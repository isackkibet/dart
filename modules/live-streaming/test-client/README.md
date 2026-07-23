# YohPal Live Browser Test Client

This is a minimal browser test client for the local Docker prototype.

## Purpose

It validates:
- HTTPS is working
- WSS is working
- JWT room join works
- signaling request/response envelope works
- `routerRtpCapabilities` is returned
- `listProducers` works
- local browser camera access works

## Start Docker

From:

```text
modules/live-streaming/
```

Run:

```bash
npm run docker:up
```

## Open client

```
https://<LAN_IP>/test-client/
```

Example:

```
https://192.168.1.10/test-client/
```

## Generate token

Broadcaster:

```bash
npm run token:broadcaster
```

Viewer:

```bash
npm run token:viewer
```

## Important limitation

This browser test client does not fully produce/consume mediasoup media.

Full browser media support would require `mediasoup-client`.

For YohPal Live, the required production client path is Flutter using:
- flutter_webrtc
- web_socket_channel

So this browser client is for endpoint and signaling validation only.
