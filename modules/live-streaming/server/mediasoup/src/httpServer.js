import express from "express";

export function createHttpServer({ config, roomRegistry, signalingServer }) {
  const app = express();
  app.use(express.json({ limit: "256kb" }));

  app.get("/health", (_req, res) => {
    res.json({ ok: true, service: "yohpal-live-mediasoup", announcedIp: config.announcedIp, rtcMinPort: config.rtcMinPort, rtcMaxPort: config.rtcMaxPort, rooms: roomRegistry.summary() });
  });

  app.get("/v1/rooms/:roomId/program", async (req, res) => {
    const room = await roomRegistry.getOrCreate(req.params.roomId);
    res.json(room.getProgram());
  });

  app.put("/internal/v1/rooms/:roomId/program", async (req, res) => {
    const expected = process.env.SFU_CONTROL_TOKEN;
    if (!expected || expected.length < 32) return res.status(503).json({ error: "SFU_CONTROL_TOKEN_NOT_CONFIGURED" });
    if (req.header("x-internal-token") !== expected) return res.status(401).json({ error: "UNAUTHORIZED_INTERNAL_CALL" });
    const { layout, activeCameraIds, updatedAt } = req.body || {};
    if (!["SINGLE", "SPLIT_SCREEN"].includes(layout)) return res.status(400).json({ error: "INVALID_LAYOUT" });
    if (!Array.isArray(activeCameraIds)) return res.status(400).json({ error: "INVALID_CAMERA_IDS" });
    const room = await roomRegistry.getOrCreate(req.params.roomId);
    const program = room.setProgram({ layout, activeCameraIds, updatedAt: updatedAt || new Date().toISOString() });
    signalingServer?.broadcastProgram(req.params.roomId, program);
    res.json({ ok: true, roomId: req.params.roomId, program, outputMode: "CLIENT_COMPOSED_SFU" });
  });

  const server = app.listen(config.apiPort, () => console.log(`HTTP health server listening on ${config.apiPort}`));
  return server;
}
