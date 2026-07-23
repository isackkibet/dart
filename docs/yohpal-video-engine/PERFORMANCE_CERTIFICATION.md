# YohPal Video Engine — Performance Certification

**Version:** V12  
**Status:** Awaiting Test Sessions  
**Certification Endpoint:** `GET /video-performance/certification/:sessionId`

---

## Required Performance Gates

All gates must pass on **both** Android and iOS before `certifiedForControlledRelease` can be `true`.

| Metric | Required Target | Android Result | Android Pass/Fail | iOS Result | iOS Pass/Fail |
|---|---:|---:|---|---:|---|
| Wi-Fi startup time (avg) | ≤ 800 ms | TBD | ⬜ | TBD | ⬜ |
| 4G startup time (avg) | ≤ 1,500 ms | TBD | ⬜ | TBD | ⬜ |
| P95 startup time | ≤ 1,500 ms | TBD | ⬜ | TBD | ⬜ |
| Average buffering time | ≤ 1,000 ms | TBD | ⬜ | TBD | ⬜ |
| Average scroll FPS | ≥ 55 FPS | TBD | ⬜ | TBD | ⬜ |
| Memory usage (avg) | ≤ 700 MB | TBD | ⬜ | TBD | ⬜ |
| Playback error rate | ≤ 2% | TBD | ⬜ | TBD | ⬜ |
| 30-minute Android stability | Pass | TBD | ⬜ | N/A | N/A |
| 30-minute iOS stability | Pass | N/A | N/A | TBD | ⬜ |
| No-CDN playback (origin only) | Pass | TBD | ⬜ | TBD | ⬜ |
| Cache-first playback on second view | Pass | TBD | ⬜ | TBD | ⬜ |
| Low-data mode enforces 360p | 360p URL selected | TBD | ⬜ | TBD | ⬜ |

---

## How to Submit a Certification Session

### Step 1 — Instrument the app

Before the test session, ensure `YohPalVideoPerformanceMetric` is being recorded per video play:

```dart
final metric = YohPalVideoPerformanceMetric(
  id: uuid(),
  deviceId: deviceId,
  userId: userId,
  videoId: videoId,
  startupMs: tracker.markFirstFrameRendered(),
  bufferingMs: tracker.totalBufferingMs,
  droppedFrames: droppedFrameCount,
  scrollFps: feedFpsMonitor.averageFps,
  memoryMb: MemoryInfo.usageMb,
  cacheHit: cacheResult.isHit,
  deliveryProvider: 'origin',
  deliveryMode: 'mp4',
  playbackError: hadError,
  testSessionId: sessionId,
  recordedAt: DateTime.now().toUtc(),
);
```

### Step 2 — Submit metrics

```bash
curl -X POST http://localhost:3001/video-performance/metrics \
  -H "Content-Type: application/json" \
  -d '{ "metrics": [ ... ] }'
```

### Step 3 — Request certification

```bash
curl http://localhost:3001/video-performance/certification/SES-AND-20260707-01
```

### Step 4 — Review result

```json
{
  "sessionId": "SES-AND-20260707-01",
  "avgStartupMs": 642,
  "p95StartupMs": 1187,
  "avgBufferingMs": 234,
  "bufferingRate": 0.12,
  "avgScrollFps": 58.4,
  "avgMemoryMb": 387,
  "droppedFramesTotal": 14,
  "cacheHitRate": 0.78,
  "playbackErrorRate": 0.008,
  "thirtyMinuteStabilityPassed": true,
  "certifiedForControlledRelease": true,
  "blockers": []
}
```

---

## Hard Gate Thresholds (from `PerformanceGateService`)

| Gate | Condition | Blocker Message |
|---|---|---|
| P95 startup | `> 1,500 ms` | "P95 startup time exceeds 1500ms" |
| Avg buffering | `> 1,000 ms` | "Average buffering time exceeds 1000ms" |
| Scroll FPS | `< 55 fps` | "Average feed scroll FPS is below 55" |
| Memory | `> 700 MB` | "Average memory usage exceeds 700MB" |
| Error rate | `> 2%` | "Playback error rate exceeds 2%" |
| 30-min stability | `false` | "30-minute stability test failed" |

---

## Session IDs to Record

| Platform | Session ID | Submitted | Certified |
|---|---|---|---|
| Android | TBD | ⬜ | ⬜ |
| iOS | TBD | ⬜ | ⬜ |
| No-CDN (Android) | TBD | ⬜ | ⬜ |
| Low-data mode | TBD | ⬜ | ⬜ |
