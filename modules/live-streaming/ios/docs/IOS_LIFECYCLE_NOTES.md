# iOS Lifecycle Notes

## Camera and microphone lifecycle

When a creator exits the live screen:
- stop WebRTC producers
- close peer connection
- stop camera/microphone tracks
- dispose `RTCVideoRenderer`
- close WebSocket signaling

## Backgrounding

For this prototype, treat app backgrounding as a stream interruption.

Production YohPal Live can later decide whether to:
- end the stream when app backgrounds
- pause and reconnect when foregrounded
- support audio-only background continuation where permitted
- implement push/live session recovery

## Important warning

iOS background execution is restricted.

Do not assume a live video session will continue reliably in the background without explicit background mode design, App Store policy review, and careful testing.

## Screen lock

For prototype certification, screen lock should be treated as a test failure unless the product requirement says the stream may end on lock.

## Thermal pressure

iPhones may throttle camera/encoding during long sessions.

Certification should include:
- 10-minute test
- 30-minute test
- battery/thermal observation
- stop/restart test
