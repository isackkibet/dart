# YohPal Live Streaming Flutter Module

This module adds Flutter-side streaming support for YohPal Live.

## Merge rule

Do not replace the existing YohPal Live Flutter app.

This module should be copied into the existing app and wired through the existing navigation system.

## Required dependencies

Add these to the existing YohPal Live Flutter `pubspec.yaml` if missing:

```yaml
dependencies:
  flutter_webrtc: ^0.11.7
  web_socket_channel: ^3.0.1
```

## Main entry point

```dart
YohPalStreamingHomeScreen(config: config)
```

## Main controllers

- YohPalBroadcasterController
- YohPalViewerController
- YohPalSignalingClient

## Important

This module is designed to work with the local mediasoup Docker stack in:

```
modules/live-streaming/docker/
```
