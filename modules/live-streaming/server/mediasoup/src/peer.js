export class Peer {
  constructor({ id, role, ws }) {
    this.id = id;
    this.role = role;
    this.ws = ws;
    this.transports = new Map();
    this.producers = new Map();
    this.consumers = new Map();
  }

  addTransport(transport) {
    this.transports.set(transport.id, transport);
  }

  getTransport(transportId) {
    return this.transports.get(transportId);
  }

  addProducer(producer) {
    this.producers.set(producer.id, producer);
  }

  addConsumer(consumer) {
    this.consumers.set(consumer.id, consumer);
  }

  closeAll() {
    for (const consumer of this.consumers.values()) {
      consumer.close();
    }
    for (const producer of this.producers.values()) {
      producer.close();
    }
    for (const transport of this.transports.values()) {
      transport.close();
    }
    this.consumers.clear();
    this.producers.clear();
    this.transports.clear();
  }
}
