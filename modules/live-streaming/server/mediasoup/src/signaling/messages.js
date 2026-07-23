export function reply(ws, action, requestId, data = {}) {
  ws.send(JSON.stringify({ action, requestId, data }));
}

export function emit(ws, action, data = {}) {
  ws.send(JSON.stringify({ action, requestId: null, data }));
}

export function error(ws, requestId, message, code = "SIGNALING_ERROR") {
  ws.send(
    JSON.stringify({
      action: "error",
      requestId,
      data: { code, message },
    })
  );
}

export function parseMessage(raw) {
  const message = JSON.parse(raw.toString());

  if (!message.action || typeof message.action !== "string") {
    throw new Error("Invalid signaling message: missing action");
  }

  if (!Object.prototype.hasOwnProperty.call(message, "requestId")) {
    throw new Error("Invalid signaling message: missing requestId");
  }

  if (!message.data || typeof message.data !== "object") {
    message.data = {};
  }

  return message;
}
