# YohPal Video Engine — Implementation Checklist

**Version:** V12  
**Status:** Pending Evidence Submission  
**Instructions:** Mark each item ✅ when developer evidence has been reviewed and accepted. Leave ❌ open until resolved.

---

## Flutter Layer

| ID | Phase | Area | File Path | Status | Evidence Required |
|---|---|---|---|---|---|
| FL-01 | V1 | Smart video abstraction | `lib/core/video/yohpal_video_engine.dart` | ⬜ Pending | Flutter playback proof — video loads and plays |
| FL-02 | V1 | Quality selector | `lib/core/video/yohpal_video_source.dart` | ⬜ Pending | 360p / 480p / 720p URL selection proof |
| FL-03 | V1 | Player pool (3-slot) | `lib/core/video/yohpal_player_pool.dart` | ⬜ Pending | Pool acquire / release proof |
| FL-04 | V1 | Cache manager | `lib/core/video/yohpal_video_cache_manager.dart` | ⬜ Pending | Cache hit on second play |
| FL-05 | V2 | Native Android bridge | `android/…/video/YohPalVideoPlugin.kt` | ⬜ Pending | ExoPlayer render proof on Android device |
| FL-06 | V2 | Native iOS bridge | `ios/Runner/Video/YohPalVideoPlugin.swift` | ⬜ Pending | AVPlayer render proof on iOS device |
| FL-07 | V3 | Smart feed player pool | `lib/core/video_feed/yohpal_smart_player_pool.dart` | ⬜ Pending | Previous / current / next slot binding proof |
| FL-08 | V3 | Preload service | `lib/core/video_feed/yohpal_feed_preload_service.dart` | ⬜ Pending | +1, +2, -1 preload logs |
| FL-09 | V5 | Feed source V5 model | `lib/core/video_feed/yohpal_feed_video_source.dart` | ⬜ Pending | `fromJson()` parses backend feed response |
| FL-10 | V6 | Watch event recording | `lib/core/video_telemetry/yohpal_watch_session.dart` | ⬜ Pending | 13 event types recorded in one session |
| FL-11 | V6 | Telemetry client flush | `lib/core/video_telemetry/yohpal_video_telemetry_client.dart` | ⬜ Pending | HTTP 200 from `/video-telemetry/events` |
| FL-12 | V7 | Offline queue persistence | `lib/core/video_telemetry_reliability/yohpal_telemetry_local_store.dart` | ⬜ Pending | Queue survives app restart |
| FL-13 | V7 | Offline sync with connectivity | `lib/core/video_telemetry_reliability/yohpal_telemetry_sync_service.dart` | ⬜ Pending | Events sync on connectivity restored |
| FL-14 | V8 | HLS / MP4 playback selector | `lib/core/video_feed/yohpal_playback_selector.dart` | ⬜ Pending | MP4 fallback proof; HLS path proof |
| FL-15 | V11 | Feature guard | `lib/core/release/yohpal_live_feature_guard.dart` | ⬜ Pending | `SizedBox.shrink()` when blocked; live page when allowed |

---

## Backend — Video Pipeline (`backend/video-pipeline/`)

| ID | Phase | Area | File Path | Status | Evidence Required |
|---|---|---|---|---|---|
| BE-01 | V4 | Upload endpoint | `src/modules/upload/upload.controller.ts` | ⬜ Pending | `POST /upload` accepts file, returns entity |
| BE-02 | V4 | FFmpeg 360p transcode | `src/modules/transcode/ffmpeg.service.ts` | ⬜ Pending | `360p.mp4` exists with faststart flag |
| BE-03 | V4 | FFmpeg 480p transcode | `src/modules/transcode/ffmpeg.service.ts` | ⬜ Pending | `480p.mp4` exists with faststart flag |
| BE-04 | V4 | FFmpeg 720p transcode | `src/modules/transcode/ffmpeg.service.ts` | ⬜ Pending | `720p.mp4` exists with faststart flag |
| BE-05 | V5 | Smart feed API | `src/modules/feed/video-feed.service.ts` | ⬜ Pending | `GET /feed` returns ranked videos with all V8 fields |
| BE-06 | V5 | Ranking formula | `src/modules/feed/feed-ranking.service.ts` | ⬜ Pending | Score calculation matches formula spec |
| BE-07 | V8 | HLS master manifest | `src/modules/transcode/hls.service.ts` | ⬜ Pending | `master.m3u8` generated after transcode |
| BE-08 | V8 | HLS variant playlists | `src/modules/transcode/hls.service.ts` | ⬜ Pending | `360p/index.m3u8`, `480p/index.m3u8`, `720p/index.m3u8` |

---

## Backend — Video Intelligence (`services/video-intelligence/`)

| ID | Phase | Area | Status | Evidence Required |
|---|---|---|---|---|
| BI-01 | V6 | Telemetry ingestion | ⬜ Pending | `POST /video-telemetry/events` returns `{ accepted: N }` |
| BI-02 | V6 | Telemetry aggregation | ⬜ Pending | Aggregate per videoId matches event counts |
| BI-03 | V7 | Retry-safe idempotency | ⬜ Pending | Duplicate eventId returns accepted without re-ingesting |
| BI-04 | V10 | Metrics ingestion | ⬜ Pending | `POST /video-performance/metrics` accepts batch |
| BI-05 | V10 | Certification endpoint | ⬜ Pending | `GET /video-performance/certification/:sessionId` returns all fields |
| BI-06 | V10 | Gate evaluation | ⬜ Pending | Failed gate produces correct blocker message |

---

## Backend — Video Delivery (`services/video-delivery/`)

| ID | Phase | Area | Status | Evidence Required |
|---|---|---|---|---|
| BD-01 | V9 | Origin provider | ⬜ Pending | Signed origin URL returned when no CDN env vars set |
| BD-02 | V9 | CDN routing fallback | ⬜ Pending | Falls back to origin when all CDN providers unavailable |
| BD-03 | V9 | Delivery metadata mapper | ⬜ Pending | All three MP4 URLs + optional HLS URL in response |

---

## Backend — Release Control (`services/release-control/`)

| ID | Phase | Area | Status | Evidence Required |
|---|---|---|---|---|
| RC-01 | V11 | Gate evaluation | ⬜ Pending | `POST /video-release/evaluate` returns `{ allowed: false, blockers[] }` when any gate fails |
| RC-02 | V11 | Rollout eligibility | ⬜ Pending | Same userId is deterministically eligible/ineligible at same percentage |
| RC-03 | V11 | Kill switch enable | ⬜ Pending | Kill switch blocks eligible user |
| RC-04 | V11 | Kill switch disable | ⬜ Pending | Eligible user passes after kill switch disabled |

---

## Certification Summary

| Total Items | ✅ Complete | ⬜ Pending | ❌ Blocked |
|---|---|---|---|
| 31 | 0 | 31 | 0 |

**All items must reach ✅ before GO decision is signed.**
