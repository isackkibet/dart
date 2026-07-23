# TLS and Domain Strategy

## Local prototype

Local prototype uses:
```text
self-signed cert
https://<LAN_IP>
wss://<LAN_IP>/ws
```

## Production

Production must use a real trusted TLS certificate.

### Recommended domains

- live-api.yohpal.com
- turn.yohpal.com
- metrics-live.yohpal.com

### nginx production requirements

The production reverse proxy must:
- terminate TLS
- support HTTP/1.1 WebSocket upgrade
- preserve Upgrade header
- preserve Connection upgrade header
- keep long read timeout for WebSocket sessions
- forward real client IP headers
- expose /health

### WebSocket proxy rule

nginx must pass the WebSocket upgrade headers correctly:

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;
proxy_read_timeout 3600s;
```

## Production prohibition

Do not ship self-signed certificate trust instructions as production configuration.
