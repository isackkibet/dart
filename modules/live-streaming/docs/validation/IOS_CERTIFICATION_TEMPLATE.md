# iOS Certification Template

## Device

- Device model:
- iOS version:
- App build:
- Network:
- Tester:
- Date:

## Pre-checks

- [ ] same Wi-Fi
- [ ] certificate installed
- [ ] certificate fully trusted
- [ ] `https://<LAN_IP>/health` opens in Safari
- [ ] app uses `wss://<LAN_IP>/ws`

## Broadcaster

- [ ] camera permission
- [ ] microphone permission
- [ ] preview visible
- [ ] joinRoom succeeds
- [ ] send transport created
- [ ] transport connected
- [ ] audio producer created
- [ ] video producer created

## Viewer

- [ ] joinRoom succeeds
- [ ] producer list received
- [ ] receive transport created
- [ ] transport connected
- [ ] consume called
- [ ] resumeConsumer called
- [ ] remote video visible
- [ ] remote audio audible

## Stability

- [ ] 10-minute test
- [ ] 30-minute test
- [ ] stop cleanup works

## Result

- PASS / FAIL / CONDITIONAL PASS

## Notes
