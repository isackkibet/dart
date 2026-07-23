import { Room } from "./room.js";

export class RoomRegistry {
  constructor({ workerManager, mediaCodecs }) {
    this.workerManager = workerManager;
    this.mediaCodecs = mediaCodecs;
    this.rooms = new Map();
  }

  async getOrCreate(roomId) {
    if (this.rooms.has(roomId)) {
      return this.rooms.get(roomId);
    }

    const worker = this.workerManager.getNextWorker();
    const router = await worker.createRouter({
      mediaCodecs: this.mediaCodecs,
    });

    const room = new Room({
      id: roomId,
      router,
      workerIndex: worker.appData?.index ?? null,
    });

    this.rooms.set(roomId, room);
    console.log(`Created room ${roomId} on worker ${room.workerIndex ?? "unknown"}`);
    return room;
  }

  get(roomId) {
    return this.rooms.get(roomId);
  }

  deleteIfEmpty(roomId) {
    const room = this.rooms.get(roomId);
    if (!room) return;
    if (room.peerCount() === 0) {
      this.rooms.delete(roomId);
      console.log(`Deleted empty room ${roomId}`);
    }
  }

  summary() {
    return Array.from(this.rooms.values()).map((room) => ({
      id: room.id,
      peers: room.peerCount(),
      viewers: room.viewerCount(),
      producers: room.producers.size,
      workerIndex: room.workerIndex,
    }));
  }
}
