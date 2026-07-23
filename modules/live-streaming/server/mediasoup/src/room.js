export class Room {
  constructor({ id, router, workerIndex }) {
    this.id = id;
    this.router = router;
    this.workerIndex = workerIndex;
    this.peers = new Map();
    this.producers = new Map();
    this.program = { layout: "SINGLE", activeCameraIds: [], updatedAt: null };
  }

  addPeer(peer) {
    this.peers.set(peer.id, peer);
  }

  removePeer(peerId) {
    this.peers.delete(peerId);
  }

  addProducer(producer) {
    this.producers.set(producer.id, producer);
  }

  removeProducer(producerId) {
    this.producers.delete(producerId);
  }

  listProducers() {
    return Array.from(this.producers.values()).map((producer) => ({
      producerId: producer.id,
      kind: producer.kind,
      peerId: producer.appData?.peerId ?? null,
    }));
  }

  setProgram(program) {
    this.program = { ...this.program, ...program };
    return this.program;
  }

  getProgram() {
    return this.program;
  }

  viewerCount() {
    return Array.from(this.peers.values()).filter(
      (peer) => peer.role === "viewer"
    ).length;
  }

  peerCount() {
    return this.peers.size;
  }
}
