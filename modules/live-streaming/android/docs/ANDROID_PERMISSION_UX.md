# Android Permission UX

Before requesting permissions, YohPal Live should explain:
- why camera is needed
- why microphone is needed
- why local network access is required
- why a foreground notification may appear during live streaming

Suggested user-facing text:

```text
YohPal Live needs access to your camera and microphone so you can broadcast live video and audio. During a live
session, YohPal may show a notification to keep your stream stable while the app is active.
```

If permission is denied:

```text
Camera or microphone permission was denied. Please enable permissions in Settings to go live.
```
