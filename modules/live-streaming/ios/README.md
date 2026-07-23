# YohPal Live iOS Native Integration

This folder contains iOS merge guidance for the YohPal Live streaming overlay.

## Purpose

Enable Flutter WebRTC streaming on iOS by adding:
- camera usage description
- microphone usage description
- local network testing guidance
- App Transport Security guidance for HTTPS/WSS local testing
- self-signed certificate trust instructions
- iOS lifecycle and background mode warnings
- device validation checklist

## Non-replacement rule

Do not replace the existing YohPal Live iOS project.

Merge the required entries into the existing iOS app.

## Required merge targets

Usually:

```text
ios/Runner/Info.plist
ios/Runner.xcodeproj
ios/Runner.xcworkspace
```

## Required Flutter dependency

The existing Flutter app must include:

```yaml
dependencies:
  flutter_webrtc: ^0.11.7
  web_socket_channel: ^3.0.1
```
