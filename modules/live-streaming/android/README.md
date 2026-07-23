# YohPal Live Android Native Integration

This folder contains Android merge files for the YohPal Live streaming overlay.

## Purpose

Enable Flutter WebRTC streaming on Android by adding:

- camera permission
- microphone permission
- internet/network permissions
- foreground service permission
- local network/self-signed certificate testing config
- optional foreground service placeholder
- Android lifecycle notes

## Non-replacement rule

Do not replace the existing YohPal Live Android project.

Merge these changes into the existing Android app manually.

## Required merge targets

Usually:

```text
android/app/src/main/AndroidManifest.xml
android/app/src/main/res/xml/network_security_config.xml
android/app/src/main/kotlin/.../YohPalLiveForegroundService.kt
```

## Required Flutter dependency

The existing Flutter app must include:

```yaml
flutter_webrtc: ^0.11.7
web_socket_channel: ^3.0.1
```
