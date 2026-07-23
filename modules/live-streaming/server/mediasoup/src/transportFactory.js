export class TransportFactory {
  constructor(config) {
    this.config = config;
  }

  async createWebRtcTransport(router) {
    return router.createWebRtcTransport({
      listenIps: [
        {
          ip: "0.0.0.0",
          announcedIp: this.config.announcedIp,
        },
      ],
      enableUdp: true,
      enableTcp: true,
      preferUdp: true,
    });
  }
}
