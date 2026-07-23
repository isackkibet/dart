# Android Debug Checklist

## Before running

- [ ] phone and development machine are on same Wi-Fi
- [ ] `.env` uses host LAN IP
- [ ] nginx cert installed on phone
- [ ] Docker stack is running
- [ ] `https://<LAN_IP>/health` opens on phone browser
- [ ] `wss://<LAN_IP>/ws` is configured in app
- [ ] TURN is configured as `turn:<LAN_IP>:3478`

## Broadcaster

- [ ] camera permission granted
- [ ] microphone permission granted
- [ ] local preview visible
- [ ] joinRoom succeeds
- [ ] send transport created
- [ ] connect transport succeeds
- [ ] audio producer request sent
- [ ] video producer request sent

## Viewer

- [ ] joinRoom succeeds
- [ ] producerList returns producers
- [ ] recv transport created
- [ ] connect transport succeeds
- [ ] consume request sent
- [ ] resumeConsumer request sent
- [ ] remote renderer receives track

## Cleanup

- [ ] stop button closes socket
- [ ] media tracks stop
- [ ] renderer disposed
- [ ] server receives peer cleanup
