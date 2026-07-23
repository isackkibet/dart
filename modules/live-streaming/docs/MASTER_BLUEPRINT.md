# YohPal Live Streaming Master Blueprint

## Objective

Upgrade the existing YohPal Live streaming foundation with a self-hosted, local-first WebRTC streaming subsystem.

This overlay must not replace the existing YohPal Live foundation.

## Stack

- Flutter UI
- flutter_webrtc
- web_socket_channel
- mediasoup v3
- Node.js
- ws WebSocket signaling
- coturn
- nginx
- Docker Compose

## Runtime architecture

```text
Flutter Broadcaster
  -> WSS signaling
  -> nginx TLS proxy
  -> Node.js ws signaling
  -> mediasoup Router/WebRtcTransport
  -> Flutter Viewer / Browser Test Client
```

## Local prototype rule

The prototype runs locally with Docker Compose.
No cloud services are required.

## Network rule

For physical devices:

```
ANNOUNCED_IP=<development-machine-LAN-IP>
```

Do not use 127.0.0.1 for physical device testing.

## Room model

Each live session is represented as a Room.

A Room owns:
- one mediasoup Router
- broadcaster peer
- viewer peers
- producers
- consumers
- transports

## Signaling envelope

Every message uses:

```json
{
  "action": "joinRoom",
  "requestId": "client-generated-id",
  "data": {}
}
```

## Required actions

**Client to server:**
- joinRoom
- createTransport
- connectTransport
- produce
- listProducers
- consume
- resumeConsumer
- leaveRoom

**Server to client:**
- routerRtpCapabilities
- transportCreated
- transportConnected
- produced
- producerList
- newProducer
- consumed
- consumerResumed
- producerClosed
- viewerCount
- error

## Prototype boundaries

**Included:**
- live video/audio proof of concept
- local TURN fallback
- TLS/WSS local entry point
- browser test client
- Flutter broadcaster/viewer module

## mediasoup server core

The mediasoup server core is responsible for:
- loading runtime configuration
- creating one mediasoup worker per CPU core
- respawning workers after unexpected death
- creating rooms
- creating routers
- creating WebRtcTransports
- exposing `/health`

The signaling server is intentionally separate and is added in Batch 4.

---

**Out of scope for this prototype:**
- recording
- simulcast
- monetization
- production auth
- cloud deployment
- horizontal scaling
- persistent chat

## WebSocket signaling server

The signaling server runs inside the same Node.js process as mediasoup.

It exposes a JSON envelope protocol:

```json
{
  "action": "joinRoom",
  "requestId": "client-generated-id",
  "data": {}
}
```

**Client actions:**
- joinRoom
- createTransport
- connectTransport
- produce
- listProducers
- consume
- resumeConsumer
- leaveRoom

**Server response/event actions:**
- routerRtpCapabilities
- transportCreated
- transportConnected
- produced
- producerList
- newProducer
- consumed
- consumerResumed
- producerClosed
- viewerCount
- error

Authentication is handled by local JWT tokens signed with `JWT_SECRET`.

## CI/CD guardrails

The streaming overlay includes CI guardrails to prevent accidental replacement of the existing YohPal Live foundation. CI validates:

- required overlay files
- Node server tests
- signaling contract
- Docker Compose config
- Flutter overlay structure
- merge safety documentation
- no dangerous root replacement paths

The overlay must pass CI before being merged into the main YohPal Live branches.

## Production readiness

Production launch requires:
- production TLS
- public WSS domain
- public TURN domain/IP
- secure backend-issued stream tokens
- device certification
- observability
- incident response
- rollback plan
- controlled pilot approval

The local prototype must not be treated as production-ready until the Go/No-Go checklist is passed.
