# YohPal Live Streaming Docker Infrastructure

This folder runs the local WebRTC prototype stack.

## Services

```text
mediasoup   -> Node.js mediasoup v3 + ws signaling
turn        -> coturn relay
nginx       -> HTTPS/WSS reverse proxy
test-client -> optional browser test page
```

## Required network rule

mediasoup and turn use:

```
network_mode: host
```

This is required for UDP media transport and TURN relay traffic.

## Start

From `modules/live-streaming/`:

```bash
npm run bootstrap
npm run certs
npm run docker:up
```

## Stop

```bash
npm run docker:down
```

## Health check

Open:

```
https://<LAN_IP>/health
```

Example:

```
https://192.168.1.10/health
```

## Browser test client

Open:

```
https://<LAN_IP>/test-client/
```

## Device testing

For physical Android/iOS device testing:

```
ANNOUNCED_IP=<host machine LAN IP>
LAN_IP=<host machine LAN IP>
```

Do not use localhost or 127.0.0.1 on a physical phone.
