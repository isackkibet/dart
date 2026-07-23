# Local Endpoint Checks

After starting Docker:

```bash
npm run docker:up
```

Run:

```bash
npm run endpoints:check
```

Expected:

```
https://<LAN_IP>/health
```

Returns JSON:

```json
{
  "ok": true,
  "service": "yohpal-live-mediasoup"
}
```

Test client:

```
https://<LAN_IP>/test-client/
```

Returns HTML.

## WebSocket endpoint

The WebSocket endpoint is:

```
wss://<LAN_IP>/ws
```

Use the browser test client or Flutter app to validate WSS behavior.

## Browser test client checks

Open:

```text
https://<LAN_IP>/test-client/
```

Then verify:
- WSS connects
- joinRoom succeeds
- routerRtpCapabilities is printed
- listProducers returns a producer list or empty array
- local camera preview works

If WSS fails:
1. confirm certificate is trusted or accepted
2. confirm nginx container is running
3. confirm mediasoup WebSocket port is running
4. confirm `/ws` location exists in nginx config
