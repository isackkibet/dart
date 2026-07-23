# Local Docker Workflow

## 1. Install requirements

Required:
- Docker
- Docker Compose
- Node.js
- npm
- OpenSSL
- Flutter SDK

## 2. Configure environment

```bash
cd modules/live-streaming
cp .env.example .env
```

Edit:

```
ANNOUNCED_IP=YOUR_MACHINE_LAN_IP
LAN_IP=YOUR_MACHINE_LAN_IP
```

Example:

```
ANNOUNCED_IP=192.168.1.10
LAN_IP=192.168.1.10
```

## 3. Bootstrap

```bash
npm run bootstrap
```

## 4. Generate TLS certs

```bash
npm run certs
```

## 5. Start stack

```bash
npm run docker:up
```

or:

```bash
bash scripts/run-local-stack.sh
```

## 6. Health check

Open:

```
https://YOUR_MACHINE_LAN_IP/health
```

The browser may warn about the self-signed certificate. Accept it for local testing.

## 7. Generate local JWT

Broadcaster:

```bash
npm run token:broadcaster
```

Viewer:

```bash
npm run token:viewer
```

## 8. Browser test client

Open:

```
https://YOUR_MACHINE_LAN_IP/test-client/
```

## 9. Flutter app

The Flutter client must point to:

```
wss://YOUR_MACHINE_LAN_IP/ws
```

TURN:

```
turn:YOUR_MACHINE_LAN_IP:3478
```

## 10. Stop stack

```bash
npm run docker:down
```

## TURN config regeneration

Whenever `.env` TURN values change, run:

```bash
npm run turn:config
```

## Endpoint check

After Docker starts:

```bash
npm run endpoints:check
```

## Certificate trust

See:

```
docs/TLS_CERTIFICATE_TRUST_GUIDE.md
```
