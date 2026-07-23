import { emit } from "./messages.js";

export function broadcastToRoom(room, action, data = {}, exceptPeerId = null) {
  for (const peer of room.peers.values()) {
    if (exceptPeerId && peer.id === exceptPeerId) continue;
    emit(peer.ws, action, data);
  }
}

export function broadcastViewerCount(room) {
  broadcastToRoom(room, "viewerCount", {
    roomId: room.id,
    count: room.viewerCount(),
    peers: room.peerCount(),
  });
}
