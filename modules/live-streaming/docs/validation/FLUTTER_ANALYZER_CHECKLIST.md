# Flutter Analyzer Checklist

Run inside the real YohPal Live Flutter app after merging the overlay.

```bash
flutter pub get
flutter analyze
```

## Expected checks

- flutter_webrtc dependency resolves
- web_socket_channel dependency resolves
- YohPalStreamingConfig imports
- YohPalStreamingHomeScreen imports
- broadcaster screen compiles
- viewer screen compiles
- no duplicate class names with existing YohPal Live files
- no route conflict with existing navigation
