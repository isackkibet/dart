import { Peer } from "../peer.js";
import { reply, error } from "./messages.js";
import { verifyJoinToken } from "./auth.js";
import { broadcastToRoom, broadcastViewerCount } from "./broadcast.js";

export class SignalingHandlers {
  constructor({ config, roomRegistry, transportFactory }) {
    this.config = config;
    this.roomRegistry = roomRegistry;
    this.transportFactory = transportFactory;
  }

  async handle({ ws, state, action, requestId, data }) {
    switch (action) {
      case "joinRoom":
        return this.joinRoom({ ws, state, requestId, data });
      case "createTransport":
        return this.createTransport({ ws, state, requestId, data });
      case "connectTransport":
        return this.connectTransport({ ws, state, requestId, data });
      case "produce":
        return this.produce({ ws, state, requestId, data });
      case "listProducers":
        return this.listProducers({ ws, state, requestId });
      case "consume":
        return this.consume({ ws, state, requestId, data });
      case "resumeConsumer":
        return this.resumeConsumer({ ws, state, requestId, data });
      case "leaveRoom":
        return this.leaveRoom({ ws });
      default:
        return error(ws, requestId, `Unknown action: ${action}`, "UNKNOWN_ACTION");
    }
  }

  async joinRoom({ ws, state, requestId, data }) {
    const { roomId, role, token } = data;

    if (!roomId) {
      return error(ws, requestId, "roomId is required", "ROOM_ID_REQUIRED");
    }

    if (!["broadcaster", "viewer"].includes(role)) {
      return error(ws, requestId, "role must be broadcaster or viewer", "INVALID_ROLE");
    }

    verifyJoinToken({
      token,
      jwtSecret: this.config.jwtSecret,
      roomId,
      role,
    });

    const room = await this.roomRegistry.getOrCreate(roomId);

    state.roomId = roomId;
    state.role = role;

    const peer = new Peer({ id: state.peerId, role, ws });
    state.peer = peer;
    room.addPeer(peer);

    reply(ws, "routerRtpCapabilities", requestId, {
      roomId,
      role,
      peerId: peer.id,
      rtpCapabilities: room.router.rtpCapabilities,
      existingProducers: room.listProducers(),
    });

    broadcastViewerCount(room);
  }

  async createTransport({ ws, state, requestId, data }) {
    const room = this.#requireRoom(ws, state, requestId);
    if (!room) return;

    const direction = data.direction || "send";

    if (!["send", "recv"].includes(direction)) {
      return error(ws, requestId, "direction must be send or recv", "INVALID_DIRECTION");
    }

    const transport = await this.transportFactory.createWebRtcTransport(room.router);
    transport.appData = { peerId: state.peer.id, direction };
    state.peer.addTransport(transport);

    reply(ws, "transportCreated", requestId, {
      id: transport.id,
      direction,
      iceParameters: transport.iceParameters,
      iceCandidates: transport.iceCandidates,
      dtlsParameters: transport.dtlsParameters,
    });
  }

  async connectTransport({ ws, state, requestId, data }) {
    const peer = this.#requirePeer(ws, state, requestId);
    if (!peer) return;

    const { transportId, dtlsParameters } = data;

    if (!transportId || !dtlsParameters) {
      return error(
        ws,
        requestId,
        "transportId and dtlsParameters are required",
        "CONNECT_TRANSPORT_INVALID"
      );
    }

    const transport = peer.getTransport(transportId);
    if (!transport) {
      return error(ws, requestId, "transport not found", "TRANSPORT_NOT_FOUND");
    }

    await transport.connect({ dtlsParameters });

    reply(ws, "transportConnected", requestId, { transportId });
  }

  async produce({ ws, state, requestId, data }) {
    const room = this.#requireRoom(ws, state, requestId);
    if (!room) return;

    const peer = this.#requirePeer(ws, state, requestId);
    if (!peer) return;

    if (peer.role !== "broadcaster") {
      return error(ws, requestId, "only broadcaster can produce", "NOT_BROADCASTER");
    }

    const { transportId, kind, rtpParameters } = data;

    if (!transportId || !kind || !rtpParameters) {
      return error(
        ws,
        requestId,
        "transportId, kind and rtpParameters are required",
        "PRODUCE_INVALID"
      );
    }

    const transport = peer.getTransport(transportId);
    if (!transport) {
      return error(ws, requestId, "transport not found", "TRANSPORT_NOT_FOUND");
    }

    const producer = await transport.produce({
      kind,
      rtpParameters,
      appData: { peerId: peer.id, roomId: room.id, kind },
    });

    peer.addProducer(producer);
    room.addProducer(producer);

    producer.on("transportclose", () => {
      room.removeProducer(producer.id);
      broadcastToRoom(room, "producerClosed", { producerId: producer.id, kind }, peer.id);
    });

    reply(ws, "produced", requestId, { producerId: producer.id, kind });

    broadcastToRoom(
      room,
      "newProducer",
      { producerId: producer.id, kind, peerId: peer.id },
      peer.id
    );
  }

  async listProducers({ ws, state, requestId }) {
    const room = this.#requireRoom(ws, state, requestId);
    if (!room) return;

    reply(ws, "producerList", requestId, { producers: room.listProducers() });
  }

  async consume({ ws, state, requestId, data }) {
    const room = this.#requireRoom(ws, state, requestId);
    if (!room) return;

    const peer = this.#requirePeer(ws, state, requestId);
    if (!peer) return;

    const { transportId, producerId, rtpCapabilities } = data;

    if (!transportId || !producerId || !rtpCapabilities) {
      return error(
        ws,
        requestId,
        "transportId, producerId and rtpCapabilities are required",
        "CONSUME_INVALID"
      );
    }

    const transport = peer.getTransport(transportId);
    const producer = room.producers.get(producerId);

    if (!transport) {
      return error(ws, requestId, "transport not found", "TRANSPORT_NOT_FOUND");
    }

    if (!producer) {
      return error(ws, requestId, "producer not found", "PRODUCER_NOT_FOUND");
    }

    if (!room.router.canConsume({ producerId, rtpCapabilities })) {
      return error(ws, requestId, "router cannot consume producer", "CANNOT_CONSUME");
    }

    const consumer = await transport.consume({ producerId, rtpCapabilities, paused: true });

    peer.addConsumer(consumer);

    consumer.on("transportclose", () => {
      peer.consumers.delete(consumer.id);
    });

    consumer.on("producerclose", () => {
      peer.consumers.delete(consumer.id);
      broadcastToRoom(room, "producerClosed", { producerId, consumerId: consumer.id });
    });

    reply(ws, "consumed", requestId, {
      consumerId: consumer.id,
      producerId,
      kind: consumer.kind,
      rtpParameters: consumer.rtpParameters,
    });
  }

  async resumeConsumer({ ws, state, requestId, data }) {
    const peer = this.#requirePeer(ws, state, requestId);
    if (!peer) return;

    const { consumerId } = data;

    if (!consumerId) {
      return error(ws, requestId, "consumerId is required", "CONSUMER_ID_REQUIRED");
    }

    const consumer = peer.consumers.get(consumerId);
    if (!consumer) {
      return error(ws, requestId, "consumer not found", "CONSUMER_NOT_FOUND");
    }

    await consumer.resume();

    reply(ws, "consumerResumed", requestId, { consumerId });
  }

  async leaveRoom({ ws }) {
    ws.close();
  }

  cleanupPeer(state) {
    const room = this.roomRegistry.get(state.roomId);
    if (!room || !state.peer) return;

    const peer = state.peer;

    for (const producer of peer.producers.values()) {
      room.removeProducer(producer.id);
      broadcastToRoom(
        room,
        "producerClosed",
        { producerId: producer.id, kind: producer.kind },
        peer.id
      );
    }

    peer.closeAll();
    room.removePeer(peer.id);
    broadcastViewerCount(room);
    this.roomRegistry.deleteIfEmpty(room.id);
  }

  #requirePeer(ws, state, requestId) {
    if (!state.peer) {
      error(ws, requestId, "peer has not joined a room", "PEER_NOT_JOINED");
      return null;
    }
    return state.peer;
  }

  #requireRoom(ws, state, requestId) {
    if (!state.roomId) {
      error(ws, requestId, "peer has not joined a room", "ROOM_NOT_JOINED");
      return null;
    }
    const room = this.roomRegistry.get(state.roomId);
    if (!room) {
      error(ws, requestId, "room not found", "ROOM_NOT_FOUND");
      return null;
    }
    return room;
  }
}
