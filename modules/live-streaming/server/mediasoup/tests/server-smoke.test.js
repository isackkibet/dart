import assert from "node:assert";
import { loadConfig } from "../src/config.js";

const config = loadConfig({
  API_PORT: "3000",
  WS_PORT: "3001",
  ANNOUNCED_IP: "192.168.1.10",
  JWT_SECRET: "test",
  RTC_MIN_PORT: "10000",
  RTC_MAX_PORT: "10100",
  MEDIASOUP_LOG_LEVEL: "warn"
});

assert.equal(config.apiPort, 3000);
assert.equal(config.wsPort, 3001);
assert.equal(config.announcedIp, "192.168.1.10");
assert.equal(config.jwtSecret, "test");
assert.equal(config.rtcMinPort, 10000);
assert.equal(config.rtcMaxPort, 10100);

assert.ok(Array.isArray(config.mediaCodecs));

const audio = config.mediaCodecs.find((codec) => codec.kind === "audio");
const vp8 = config.mediaCodecs.find((codec) => codec.mimeType === "video/VP8");
const h264 = config.mediaCodecs.find((codec) => codec.mimeType === "video/H264");

assert.ok(audio);
assert.ok(vp8);
assert.ok(h264);

console.log("server smoke test passed");
