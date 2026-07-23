# Android Merge Guide

## 1. Merge permissions

Open existing:

```text
android/app/src/main/AndroidManifest.xml
```

Add permissions from:

```text
modules/live-streaming/android/AndroidManifest.merge.xml
```

Do not replace the full manifest.

## 2. Add network security config

Create:

```text
android/app/src/main/res/xml/yohpal_live_network_security_config.xml
```

Then add to existing `<application>`:

```xml
android:networkSecurityConfig="@xml/yohpal_live_network_security_config"
android:usesCleartextTraffic="false"
```

## 3. Add foreground service

Copy Kotlin files into the existing Android package:

- `YohPalLiveForegroundService.kt`
- `YohPalLiveForegroundServiceController.kt`

Update package declarations.

Then add the service declaration to the existing manifest.

## 4. Runtime permissions

Flutter must request:
- camera
- microphone

The `flutter_webrtc` camera call may trigger permission requests, but production YohPal Live should still provide clear pre-permission UX.

## 5. Certificate trust

For local testing, install:

```text
modules/live-streaming/docker/certs/localhost.crt
```

on the Android device as a user CA certificate.

## 6. Physical device rule

Use:

```text
wss://<HOST_LAN_IP>/ws
turn:<HOST_LAN_IP>:3478
```

Do not use:
- localhost
- 127.0.0.1

inside the Android app when testing on a physical phone.
