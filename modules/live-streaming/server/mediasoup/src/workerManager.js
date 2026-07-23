import * as mediasoup from "mediasoup";

export class WorkerManager {
  constructor(config) {
    this.config = config;
    this.workers = [];
    this.nextWorkerIndex = 0;
  }

  async start() {
    const count = this.config.numWorkers;
    for (let index = 0; index < count; index += 1) {
      const worker = await this.#createWorker(index);
      this.workers.push(worker);
    }
    console.log(`Started ${this.workers.length} mediasoup workers`);
  }

  getNextWorker() {
    if (this.workers.length === 0) {
      throw new Error("No mediasoup workers available");
    }
    const worker = this.workers[this.nextWorkerIndex % this.workers.length];
    this.nextWorkerIndex += 1;
    return worker;
  }

  async #createWorker(index) {
    const worker = await mediasoup.createWorker({
      logLevel: this.config.mediasoupLogLevel,
      rtcMinPort: this.config.rtcMinPort,
      rtcMaxPort: this.config.rtcMaxPort,
    });

    worker.appData = { index };

    worker.on("died", () => {
      console.error(`mediasoup worker ${index} died`);
      setTimeout(async () => {
        try {
          const replacement = await this.#createWorker(index);
          this.workers[index] = replacement;
          console.log(`mediasoup worker ${index} respawned`);
        } catch (error) {
          console.error(`failed to respawn mediasoup worker ${index}`, error);
        }
      }, 2000);
    });

    return worker;
  }
}
