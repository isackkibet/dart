import "dotenv/config";
import { loadConfig } from "./config.js";
import { WorkerManager } from "./workerManager.js";
import { RoomRegistry } from "./roomRegistry.js";
import { TransportFactory } from "./transportFactory.js";
import { createHttpServer } from "./httpServer.js";
import { SignalingServer } from "./signaling/signalingServer.js";

const config = loadConfig();
const workerManager = new WorkerManager(config); await workerManager.start();
const roomRegistry = new RoomRegistry({ workerManager, mediaCodecs: config.mediaCodecs });
const transportFactory = new TransportFactory(config);
const signalingServer = new SignalingServer({ config, roomRegistry, transportFactory });
signalingServer.start();
createHttpServer({ config, roomRegistry, signalingServer });
console.log("YohPal mediasoup server with signaling started");
console.log(`Announced IP: ${config.announcedIp}`);console.log(`HTTP API port: ${config.apiPort}`);console.log(`WebSocket port: ${config.wsPort}`);console.log(`RTC ports: ${config.rtcMinPort}-${config.rtcMaxPort}`);
