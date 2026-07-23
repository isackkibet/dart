# YohPal Video Engine — Architecture Summary

**Version:** V12  
**Status:** Pending Final Certification  
**Date:** 2026-07-07  

---

## Objective

Deliver fast, smooth, and reliable short-form video playback for YohPal Live without depending on a single Flutter video library, a CDN provider, or any external streaming infrastructure.

The engine is designed to work in low-connectivity African markets from day one, with a clear upgrade path to HLS adaptive streaming and CDN edge delivery when those are available.

---

## Core Components

### V1 — Smart Flutter Video Abstraction Layer
**Path:** `lib/core/video/`  
Wraps `media_kit` behind a stable interface. Decouples feed UI from the player implementation. Provides quality selection (360p / 480p / 720p / HLS), cache-first playback, and metric collection.

### V2 — Native Performance Bridge
**Path:** `lib/core/video_native/` + Android `YohPalVideoPlugin.kt` + iOS `YohPalVideoPlugin.swift`  
MethodChannel (`yohpal.video/native`) and PlatformView (`yohpal.video/view`) bridge connecting Dart to ExoPlayer (Android) and AVPlayer (iOS). Eliminates cross-platform overhead for playback-critical operations.

### V3 — Smart Feed Player Pool
**Path:** `lib/core/video_feed/`  
Three-slot sliding window (previous / current / next). `YohPalSmartPlayerPool` binds the window on every page change. Autoplay is restricted to the current slot. `YohPalFeedPreloadService` warms `+1`, `+2`, `-1` around the current index.

### V4 — Upload & Transcoding Pipeline
**Path:** `backend/video-pipeline/`  
NestJS service on port 3000. Accepts multipart upload, stores original, transcodes to three faststart MP4 variants (360p / 480p / 720p) using FFmpeg with `-movflags +faststart`. In-process serial queue; swap-in for a message queue later.

### V5 — Feed Ranking & Preload Intelligence
**Path:** `backend/video-pipeline/src/modules/feed/`  
Ranking formula: `engagement(0.35×completion + 0.15×replay + 0.15×like + 0.10×comment + 0.15×share) + trust(0.10×creatorScore − 0.30×penalty) + freshnessBoost`. Preload priority ladder: 1 / 2 / 3 / 5 / 8 (highest to lowest). Quality recommendation: HLS+CDN → 720p wifi → 480p 4G → 360p 3G/low-data.

### V6 — Watch Telemetry & Feedback Loop
**Path:** `lib/core/video_telemetry/` + `services/video-intelligence/src/modules/telemetry/`  
Flutter records 13 event types (impression, play, pause, skip, complete, replay, like, comment, share, bufferStart, bufferEnd, startupMeasured, error). Buffered at 20 events; flushed on batch fill or session end. Backend ingests, aggregates per video, feeds back into ranking scores.

### V7 — Offline Telemetry Queue & Reliability Guard
**Path:** `lib/core/video_telemetry_reliability/`  
Events persisted to `SharedPreferences` when network is unavailable. `YohPalTelemetrySyncService` checks connectivity before each sync attempt. Exponential backoff: 5 s → 30 s → 2 min → 10 min. Backend deduplicates by `eventId` at `/events/retry-safe`. Telemetry failure never blocks playback.

### V8 — HLS Preparation & Adaptive Streaming Layer
**Path:** `backend/video-pipeline/src/modules/transcode/hls.service.ts` + `lib/core/video_feed/yohpal_playback_selector.dart`  
FFmpeg generates `master.m3u8` + three variant playlists (`360p/index.m3u8`, `480p/index.m3u8`, `720p/index.m3u8`) + 2-second TS segments after each MP4 transcode. Flutter `YohPalPlaybackSelector` routes to HLS when `hlsReady = true` and CDN is available; falls back to faststart MP4 otherwise. Old MP4 clients remain supported.

### V9 — CDN Abstraction & Edge Delivery Readiness
**Path:** `services/video-delivery/`  
`CdnProvider` interface satisfied by: `OriginProvider` (always available), `CloudflareProvider`, `BunnyProvider`, `CloudFrontProvider`, `RegionalProvider`. `CdnRoutingService` selects preferred → first available non-origin → origin fallback. Activated by environment variables (`CLOUDFLARE_CDN_DOMAIN`, `BUNNY_CDN_DOMAIN`, `CLOUDFRONT_DOMAIN`, `REGIONAL_CDN_DOMAIN`). Flutter contract unchanged — only the URL hostname changes.

### V10 — Performance Certification Dashboard
**Path:** `services/video-intelligence/src/modules/performance/`  
Ingests `YohPalVideoPerformanceMetric` records by session. `PerformanceSummaryService` computes avg startup, P95 startup, avg buffering, buffering rate, scroll FPS, memory, dropped frames, cache hit rate, error rate, delivery mode split. `PerformanceGateService` evaluates 6 hard gates. `GET /video-performance/certification/:sessionId` returns the full certification summary with `certifiedForControlledRelease` boolean and `blockers[]`.

### V11 — Release Lock & Controlled Rollout Gate
**Path:** `services/release-control/` + `lib/core/release/yohpal_live_feature_guard.dart`  
`YohPalVideoReleaseLock` entity encodes all 12 gate fields. `YohPalVideoReleaseGateService.canRelease()` returns `{ allowed, blockers[] }`. `YohPalVideoRolloutService.isUserEligible()` uses a deterministic djb2 hash bucket — same user lands in the same bucket every call. `YohPalVideoKillSwitchService` overrides all other gates instantly. Flutter `YohPalLiveFeatureGuard.canShowYohPalLive` returns `false` if any condition fails; `buildYohPalLiveEntry()` renders `SizedBox.shrink()` when blocked.

---

## Current Delivery Mode

```
Upload → FFmpeg transcode → 360p.mp4 / 480p.mp4 / 720p.mp4 (faststart)
                          → HLS master.m3u8 + variant playlists (generated, not yet served via CDN)
Origin storage → Signed URL → Flutter player
```

## Future Delivery Mode

```
Upload → FFmpeg transcode → MP4 + HLS
Origin storage → CDN edge provider → Signed CDN URL → Flutter player (HLS adaptive)
```

Activating the CDN path requires setting one environment variable and setting `cdnAvailable: true` in `YohPalDeliveryDecisionService.decide()`. No Flutter code changes required.

---

## Production Rule

**YohPal Live remains disabled in production until V12 certification is approved and the `YohPalVideoReleaseLock` passes all 12 gates.**

See `GO_NO_GO_DECISION_FORM.md`.
