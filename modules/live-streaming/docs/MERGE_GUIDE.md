# YohPal Live Streaming Merge Guide

## Rule

This module updates YohPal Live streaming. It must not replace the existing app foundation.

## Safe merge path

Copy this folder into the existing YohPal Live repo:

```text
modules/live-streaming/
```

Then wire Flutter entry points into the existing app navigation.

## Flutter dependencies

Add to the existing YohPal Live Flutter app if missing:

```yaml
dependencies:
  flutter_webrtc: ^0.11.7
  web_socket_channel: ^3.0.1
```

## Main Flutter entry point

```dart
YohPalStreamingHomeScreen(config: config)
```

## Do not overwrite

- existing main.dart
- existing authentication
- existing navigation shell
- existing creator profile/feed
- existing wallet/monetization
- existing Firebase setup
- existing backend APIs

## Integration responsibility

**Existing YohPal Live should own:**
- user identity
- creator profile
- stream title/category
- permissions
- monetization
- analytics
- routing

**The streaming overlay owns:**
- signaling
- local camera preview
- WebRTC session flow
- local mediasoup prototype integration

## Flutter module integration example

Inside the existing YohPal Live app, create a route similar to:

```dart
import 'package:yohpal_live_streaming/yohpal_live_streaming.dart';

final config = YohPalStreamingConfig(
  wsUrl: 'wss://192.168.1.10/ws',
  roomId: 'room1',
  jwtToken: '<local-or-backend-issued-jwt>',
  lanIp: '192.168.1.10',
  turnUsername: 'localuser',
  turnPassword: 'localpass',
);

Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => YohPalStreamingHomeScreen(config: config),
  ),
);
```

In production, the JWT token and room ID must come from YohPal Live backend/session services.

## YohPal UI integration

The streaming overlay now includes YohPal-branded UI screens.

Entry screen:

```dart
YohPalStreamingHomeScreen(config: config)
```

Recommended existing-app integration:

1. Add a "Go Live" or "Live Studio" button inside the existing YohPal Live creator dashboard.
2. Generate or fetch the `YohPalStreamingConfig` from the existing YohPal Live backend/session layer.
3. Navigate to `YohPalStreamingHomeScreen`.
4. Do not replace the existing app shell, authentication, profile, video feed, wallet, or monetization modules.

Example file:

```
modules/live-streaming/flutter/lib/src/ui/yohpal_existing_app_integration_example.dart
```

## Android native merge

The Android overlay files are in:

```text
modules/live-streaming/android/
```

Merge them into the existing YohPal Live Android app.

Required:
- Android permissions
- network security config
- optional foreground service

Do not replace the existing Android manifest. Merge the required entries only.

See:

```
modules/live-streaming/android/docs/ANDROID_MERGE_GUIDE.md

## iOS native merge

The iOS overlay files are in:

```text
modules/live-streaming/ios/
```

Required merge work:

- add camera usage description
- add microphone usage description
- add local network usage description for local prototype testing
- trust self-signed certificate on device
- keep ATS strict for production
- run physical device validation

Do not replace the existing iOS project.

See:

```
modules/live-streaming/ios/docs/IOS_MERGE_GUIDE.md
```
```
