# YohPal Live Streaming Overlay

This module upgrades YohPal Live streaming features without replacing the existing YohPal Live foundation.

## Purpose

Adds a local-first, self-hosted live streaming SDK prototype using:

- Flutter
- flutter_webrtc
- web_socket_channel
- mediasoup v3
- Node.js ws signaling
- coturn
- nginx TLS/WSS proxy
- Docker Compose

## Non-replacement rule

Do not replace existing YohPal Live app files.

This module should be merged as an overlay and connected through existing YohPal Live navigation.

## Main folders

```text
modules/live-streaming/
  docs/
  flutter/
  server/
  docker/
  scripts/
  test-client/
  tests/
```

## Start order

1. Configure .env
2. Generate certificates
3. Start Docker stack
4. Mint local JWT
5. Run Flutter app/device
6. Test broadcaster
7. Test viewer

## Final developer handover

Before any developer begins implementation, they must read:

```text
docs/FINAL_DEVELOPER_HANDOVER_MANUAL.md
```

This manual is binding for merge order, validation evidence, and production restrictions.
