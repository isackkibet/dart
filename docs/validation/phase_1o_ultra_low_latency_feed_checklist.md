# Phase 1O — Ultra-Low Latency Feed Validation Checklist

## Required Commands

```bash
flutter analyze
flutter test
cd backend/firebase_functions
npm run build
npm test
firebase deploy --only functions:validateUltraLowLatencyFeed1O
```

## Android 30-Swipe Test

- Open Suggested feed.
- Swipe through 30 videos.
- Confirm no black poster.
- Confirm no broken/unready video appears.
- Confirm playback starts under 500ms on good network.
- Confirm next video is already warm.

## iOS 30-Swipe Test

- Repeat same test on iOS physical device.
- Record average playback start time.

## Backend Validation

Run callable: `validateUltraLowLatencyFeed1O`

Pass condition:

```json
{
  "missingThumbnail": 0,
  "missingHls": 0,
  "readyForPilot": true
}
```
