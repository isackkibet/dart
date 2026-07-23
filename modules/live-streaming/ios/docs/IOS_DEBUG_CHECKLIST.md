# iOS Debug Checklist

## Before running
- [ ] iPhone and development machine are on same Wi-Fi
- [ ] `.env` uses host LAN IP
- [ ] nginx TLS certificate generated
- [ ] certificate installed on iPhone
- [ ] certificate fully trusted in Certificate Trust Settings
- [ ] Docker stack is running
- [ ] `https://<LAN_IP>/health` opens in Safari
- [ ] Flutter app uses `wss://<LAN_IP>/ws`
- [ ] TURN uses `turn:<LAN_IP>:3478`

## Xcode
- [ ] `ios/Runner.xcworkspace` opens
- [ ] signing team selected
- [ ] physical device selected
- [ ] developer mode enabled if needed
- [ ] build succeeds

## Broadcaster
- [ ] camera permission prompt appears
- [ ] microphone permission prompt appears
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
- [ ] stop button closes WebSocket
- [ ] media tracks stop
- [ ] renderer disposed
- [ ] server receives peer cleanup
