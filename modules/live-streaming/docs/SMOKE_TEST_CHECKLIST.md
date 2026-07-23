# Smoke Test Checklist

## Browser client

- [ ] `https://<LAN_IP>/test-client/` opens
- [ ] browser accepts local TLS certificate
- [ ] WSS connection opens
- [ ] `joinRoom` returns `routerRtpCapabilities`
- [ ] `listProducers` returns response
- [ ] local camera preview works
- [ ] `viewerCount` event appears after join

## Validation scripts

- [ ] `npm run doctor`
- [ ] `npm run test`
- [ ] `npm run docker:health`
- [ ] `npm run browser:checklist`
- [ ] Flutter analyzer passes inside real YohPal Live app
