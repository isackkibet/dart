# Android Lifecycle Notes

## Camera/microphone lifecycle

When the creator leaves the live screen:
- stop WebRTC producers
- close peer connection
- stop local media tracks
- dispose `RTCVideoRenderer`
- stop foreground service if used

## Screen lock/backgrounding

For prototype testing, treat backgrounding as a stream interruption.

Production YohPal Live can later decide whether to:
- end the stream when app backgrounds
- keep audio only
- keep full stream using foreground service
- pause stream and reconnect

## Foreground service warning

Android foreground services for camera/microphone require correct permission handling and user-visible notification.

For production, do not start the foreground service silently.

## Device-specific testing

Validate at least:
- Samsung
- Pixel
- Tecno/Infinix
- Xiaomi/Redmi

Each must pass:
- camera preview
- microphone capture
- WSS join
- produce audio
- produce video
- viewer consume
- stop stream cleanup
