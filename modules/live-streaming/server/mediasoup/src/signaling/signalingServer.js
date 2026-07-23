import { WebSocketServer } from "ws";
import { parseMessage, error } from "./messages.js";
import { SignalingHandlers } from "./handlers.js";

export class SignalingServer {
  constructor({ config, roomRegistry, transportFactory }) {
    this.config = config;
    this.roomRegistry = roomRegistry;
    this.transportFactory = transportFactory;
    this.handlers = new SignalingHandlers({ config, roomRegistry, transportFactory });
  }

  broadcastProgram(roomId, program) {
    if (!this.wss) return;
    const payload = JSON.stringify({ action: "program-layout", data: { roomId, ...program } });
    for (const client of this.wss.clients) {
      if (client.readyState === 1) client.send(payload);
    }
  }

  start() {
    this.wss = new WebSocketServer({ port: this.config.wsPort });

    this.wss.on("connection", (ws) => {
      const state = {
        peerId: crypto.randomUUID(),
        roomId: null,
        role: null,
        peer: null,
      };

      ws.on("message", async (raw) => {
        let message;
        try {
          message = parseMessage(raw);
        } catch (parseError) {
          return error(ws, null, parseError.message, "INVALID_MESSAGE");
        }

        try {
          await this.handlers.handle({
            ws,
            state,
            action: message.action,
            requestId: message.requestId,
            data: message.data,
          });
        } catch (handlerError) {
          error(
            ws,
            message.requestId,
            handlerError.message || "Unhandled signaling error",
            "HANDLER_ERROR"
          );
        }
      });

      ws.on("close", () => {
        this.handlers.cleanupPeer(state);
      });

      ws.on("error", () => {
        this.handlers.cleanupPeer(state);
      });
    });

    console.log(`WebSocket signaling listening on ${this.config.wsPort}`);
  }
}
