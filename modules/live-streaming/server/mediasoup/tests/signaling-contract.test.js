import assert from "node:assert";

const requiredClientActions = [
  "joinRoom",
  "createTransport",
  "connectTransport",
  "produce",
  "listProducers",
  "consume",
  "resumeConsumer",
  "leaveRoom"
];

const requiredServerActions = [
  "routerRtpCapabilities",
  "transportCreated",
  "transportConnected",
  "produced",
  "producerList",
  "newProducer",
  "consumed",
  "consumerResumed",
  "producerClosed",
  "viewerCount",
  "error"
];

function assertEnvelope(message) {
  assert.equal(typeof message.action, "string");
  assert.ok(Object.prototype.hasOwnProperty.call(message, "requestId"));
  assert.equal(typeof message.data, "object");
}

for (const action of requiredClientActions) {
  assertEnvelope({
    action,
    requestId: "test-request",
    data: {}
  });
}

for (const action of requiredServerActions) {
  assertEnvelope({
    action,
    requestId: action === "viewerCount" ? null : "test-request",
    data: {}
  });
}

console.log("signaling contract test passed");
