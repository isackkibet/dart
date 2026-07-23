# Feature Activation Summary

**Date:** 2026-06-08  
**Branch:** develop  
**Source of truth:** `docs/FEATURE_ACCESSIBILITY_AUDIT.md`

---

## Activated Workflows

All fixes were applied to `apps/mobile_flutter/`. No new architecture was introduced — every change wires existing implementations together.

---

### P0 — Critical Bug Fixes

| Fix | File | Change |
|-----|------|--------|
| Double camera start on Go Live | `live_rtc/screens/live_start_screen.dart` | Split into `_startPreview()` (camera only) + `_goLive()` (reuses `_previewStream`, no second camera open) |
| Live session not marked live | `live_rtc/screens/live_start_screen.dart` | Added `await _repo.updateStatus(_sessionId!, LiveSessionStatus.live)` after successful publish |

---

### P1 — Route / Wiring / Entry-Point Fixes

| Fix | Files Changed | Change |
|-----|---------------|--------|
| `UploadVideoScreen` didn't exist | `upload/screens/upload_video_screen.dart` (created) | Full screen: `ImagePicker`, `VideoValidationService`, `VideoUploadService` with progress, navigates to `videoProcessingStatus` on success |
| `ScreenFactory.uploadVideo()` missing | `core/factories/screen_factory.dart` | Added `static Widget uploadVideo() => const UploadVideoScreen()` + removed dead `goLive()` method |
| Upload Video not reachable | `core/routing/yohpal_routes.dart` | Route constant `uploadVideo = '/upload-video'` (added in prior batch) |
| Upload Video not in router | `app/router.dart` | Route case wired to `ScreenFactory.uploadVideo()` (added in prior batch) |
| Upload Video not in FAB menu | `app/app_shell.dart` | Added to FAB "+" sheet (added in prior batch) |
| Search not reachable | `core/routing/yohpal_routes.dart`, `app/router.dart`, `app/app_shell.dart` | Route constant, router case, and FAB entry all added in prior batch |
| Live Now sessions undiscoverable | `feed/screens/suggested_feed_screen.dart` | Added `_LiveNowRow` widget — horizontal scroll of active live sessions, tapping opens `liveRtcViewer` |
| `LiveRtcSessionRepository.watchActiveSessions()` missing | `live_rtc/services/live_session_repository.dart` | Added `watchActiveSessions()` streaming `liveSessions where status==live orderBy startedAt` |
| Product pinning not reachable from host screen | `live_rtc/screens/live_start_screen.dart` | Added "Pin Product" FAB (visible when `_isLive == true`) → bottom sheet → `LiveProductRepository.pinProduct()` |
| Purchase history not reachable | `wallet_web/screens/wallet_status_screen.dart` | Added "My Purchases" tile (added in prior batch) |
| Merchant dashboard not reachable | `business_os/screens/business_dashboard_screen.dart` | Added "Live Sales Dashboard" action card (added in prior batch) |

---

### P2 — Partially Wired Features Completed

| Fix | File | Change |
|-----|------|--------|
| Live commerce invisible to viewers | `live_rtc/screens/live_rtc_viewer_screen.dart` | Added `StreamBuilder` on `watchPinnedProducts`, renders `LivePinnedProductCard`, `onPayNow` creates `businessOrders` doc + shows `LivePaymentOptionsSheet` |
| `CreatorProfileScreen` was a stub | `creator_profile/screens/creator_profile_screen.dart` | Replaced with real screen: avatar, display name, role chip, navigation tiles to Settings, Earnings, My Purchases, Merchant Dashboard, Upload Video, AI Creator Studio |

---

### Cleanup

| Item | Status |
|------|--------|
| Dead `goLive()` in `ScreenFactory` | Removed — replaced by `uploadVideo()` |
| `image_picker: ^1.1.2` in `pubspec.yaml` | Present (added in prior batch) |

---

## Files Changed

### Created
- `apps/mobile_flutter/lib/features/upload/screens/upload_video_screen.dart`

### Modified
- `apps/mobile_flutter/lib/core/factories/screen_factory.dart` — added `uploadVideo()`, removed `goLive()`
- `apps/mobile_flutter/lib/core/routing/yohpal_routes.dart` — `uploadVideo`, `search` constants
- `apps/mobile_flutter/lib/app/router.dart` — `uploadVideo`, `search` route cases
- `apps/mobile_flutter/lib/app/app_shell.dart` — FAB menu (Upload Video, Go Live, Search, AI Creator Studio, Settings)
- `apps/mobile_flutter/lib/features/feed/screens/suggested_feed_screen.dart` — Live Now row
- `apps/mobile_flutter/lib/features/live_rtc/services/live_session_repository.dart` — `watchActiveSessions()` + `startedAt` field
- `apps/mobile_flutter/lib/features/live_rtc/screens/live_start_screen.dart` — split preview/publish, status update, product pinning FAB
- `apps/mobile_flutter/lib/features/live_rtc/screens/live_rtc_viewer_screen.dart` — pinned product card + payment sheet
- `apps/mobile_flutter/lib/features/creator_profile/screens/creator_profile_screen.dart` — full profile replacing stub
- `apps/mobile_flutter/lib/features/wallet_web/screens/wallet_status_screen.dart` — My Purchases tile
- `apps/mobile_flutter/lib/features/business_os/screens/business_dashboard_screen.dart` — Live Sales Dashboard card
- `apps/mobile_flutter/lib/features/live_rtc/widgets/live_chat_overlay.dart` — `displayName` field in chat message
- `apps/mobile_flutter/pubspec.yaml` — `image_picker: ^1.1.2`

---

## User Journey Coverage

| Journey | Before | After |
|---------|--------|-------|
| Upload a video | FAB present, screen missing → crash | FAB → `UploadVideoScreen` → progress → processing status |
| Search content | Not in any menu | FAB → `SearchScreen` |
| Go live | Double camera start, session stuck at `starting` | Preview → single camera open → Publish → status set to `live` |
| Pin product during live | No entry point | "Pin Product" FAB (host-only, shown when live) → bottom sheet → Firestore |
| Discover live sessions | None | "Live Now" row on feed tab, tap opens viewer |
| Buy during live | Viewer had no product UI | Product card appears when host pins; "Pay Now" → M-Pesa or Wallet |
| View profile / navigate to sub-features | Stub screen, no navigation | Avatar, display name, role, 6 navigation tiles |
| Access purchase history | No entry point | Wallet tab → "My Purchases" |
| Access merchant dashboard | No entry point | Business tab → "Live Sales Dashboard" |

---

## `dart analyze lib/` Result

**0 errors · 0 warnings** (all `flutter analyze` errors are in `build/ios/SourcePackages` — pre-existing iOS SPM cache conflicts, not our source).
