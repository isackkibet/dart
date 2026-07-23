import os from "node:os";

export function loadConfig(env = process.env) {
  return {
    apiPort: Number(env.API_PORT || 3000),
    wsPort: Number(env.WS_PORT || 3001),

    announcedIp: env.ANNOUNCED_IP || "127.0.0.1",
    jwtSecret: env.JWT_SECRET || "change-me-local-secret",

    rtcMinPort: Number(env.RTC_MIN_PORT || 10000),
    rtcMaxPort: Number(env.RTC_MAX_PORT || 10100),

    numWorkers: Math.max(1, os.cpus().length),
    mediasoupLogLevel: env.MEDIASOUP_LOG_LEVEL || "warn",

    mediaCodecs: [
      {
        kind: "audio",
        mimeType: "audio/opus",
        clockRate: 48000,
        channels: 2,
      },
      {
        kind: "video",
        mimeType: "video/VP8",
        clockRate: 90000,
      },
      {
        kind: "video",
        mimeType: "video/H264",
        clockRate: 90000,
        parameters: {
          "packetization-mode": 1,
          "profile-level-id": "42e01f",
          "level-asymmetry-allowed": 1,
        },
      },
    ],
  };
}
