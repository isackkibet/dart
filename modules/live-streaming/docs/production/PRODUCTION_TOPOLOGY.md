# YohPal Live Streaming Production Topology

## Objective

Move the YohPal Live streaming overlay from local prototype readiness toward production readiness without replacing the existing YohPal Live foundation.

## Production topology

```text
YohPal Live Flutter App
  -> Production HTTPS/WSS Domain
  -> Edge Load Balancer / nginx
  -> Signaling API
  -> mediasoup SFU Node
  -> TURN/STUN Public Relay
  -> Observability Pipeline
  -> YohPal Live Backend Session/Auth Services
```

## Required production services

### 1. Signaling domain

Example:
```
wss://live-api.yohpal.com/ws
https://live-api.yohpal.com/health
```

### 2. TURN domain

Example:
```
turn:turn.yohpal.com:3478
turns:turn.yohpal.com:5349
```

### 3. mediasoup SFU node

Runs:
- mediasoup workers
- room registry
- transport lifecycle
- producer lifecycle
- consumer lifecycle
- signaling handlers

### 4. YohPal Live backend

Owns:
- user identity
- creator authorization
- stream session creation
- stream title/category
- viewer access rules
- token issuance
- analytics
- monetization
- moderation hooks

## Production rule

Do not let the Flutter app mint tokens. Flutter must request a short-lived stream token from the YohPal Live backend.
