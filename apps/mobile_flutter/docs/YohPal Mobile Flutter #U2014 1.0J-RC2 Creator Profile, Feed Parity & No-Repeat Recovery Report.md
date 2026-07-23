# YohPal Mobile Flutter — 1.0J-RC2 Creator Profile, Feed Parity & No-Repeat Recovery Report

Date: 2026-07-15
Release candidate: `yohpal-live-v1.0j-rc2`

## Scope
This report is based on the code changes reviewed today and the release guidance provided in the `YOHPAL LIVE RELEASE 1.0J-RC2` directive.

It covers:
- creator identity visibility in the video overlay
- creator profile video grid and profile UX
- public vs. owner-only profile categories
- feed category parity for Recommended and Following
- no-repeat recommendation behavior and exclusion logic
- the specific RC2 release identity and certification wiring

## Key code references
- `apps/mobile_flutter/lib/features/video_feed/widgets/video_overlay_widget.dart`
- `apps/mobile_flutter/lib/features/video_feed/screens/video_feed_screen.dart`
- `apps/mobile_flutter/lib/features/video_feed/controllers/video_feed_controller.dart`
- `apps/mobile_flutter/lib/features/video_feed/models/video_model.dart`
- `apps/mobile_flutter/lib/features/creator_profile/screens/creator_profile_screen.dart`
- `apps/mobile_flutter/lib/features/creator_profile/models/creator_profile_model.dart`
- `apps/mobile_flutter/lib/features/creator_profile/repositories/creator_profile_repository.dart`
- `apps/mobile_flutter/lib/core/release/qa_release_identity.dart`
- `apps/mobile_flutter/lib/core/observability/crashlytics_verification_service.dart`

## Findings

### 1. Creator identity visibility
- The current overlay implementation already renders creator identity in `VideoOverlayWidget`.
- It shows `displayName` when available, falls back to `@username`, and displays a verified icon using `video.ownerVerified`.
- The overlay is tappable and navigates to `/creator-profile` via `VideoFeedScreen._showCreatorProfile`.
- Current limitations:
  - there is no dedicated `CreatorIdentityBlock` widget as requested,
  - the overlay does not explicitly enforce the exact requested `TextOverflow.ellipsis` semantics for long names,
  - it uses the existing `VideoOverlayWidget` rather than the requested component interface.

### 2. Creator profile video list
- `CreatorProfileScreen` already exposes a public video grid below the profile header.
- It supports:
  - loading state with `CircularProgressIndicator`,
  - videos available grid display,
  - empty state text when no public videos exist,
  - error state when the video stream fails.
- Current implementation uses a simple `GridView.builder` and video thumbnail tap to open `CreatorVideoFeedScreen`.
- Current limitations:
  - it does not yet separate public vs owner-only categories,
  - it does not render the exact requested `CreatorVideoGrid` abstraction,
  - it does not explicitly handle blocked creators or restricted minor-content profiles in the UI.

### 3. Creator-profile categories
- The codebase currently does not implement a `CreatorLibraryTabs` category selector or `CreatorLibraryCategory` enum.
- `CreatorProfileScreen` only renders the public videos list and does not expose owner-only tabs like `Drafts`, `Private`, `Saved`, or `History`.
- The profile model and repository do include username/displayName/status metadata, which can support category-based UI.
- No owner-only category access control is currently enforced at the Flutter UI layer.

### 4. No-repeat recommendation logic
- `VideoFeedController` implements `_recentlyViewedVideoIds` and excludes those IDs from suggested/trending feed results in `_filter()`.
- This is a session-only forward-feed exclusion.
- The code already supports "do not repeat automatically in normal forward swiping" for suggested/trending feeds.
- Current limitations:
  - there is no persistent local store for automatic feed exclusions across app restarts,
  - there is no server-side exposure state or explicit `excludedVideoIds` in feed requests,
  - the current filter is tied to video metadata and may over-filter due to strict minor-safety gating.

### 5. Recommended / Following feed parity
- `VideoFeedScreen` currently renders feed tabs for `Recommended`, `Following`, and `Trending`.
- This feed category selector is platform-agnostic and should appear on both Android and iOS with the same UI.
- Current limitations:
  - there is no dedicated iOS-specific `FeedCategorySelector` widget,
  - there is no test coverage currently visible for iOS category parity,
  - the `Following` feed loads via `VideoFeedController.startFollowingFeed` only when the user is signed in.

### 6. QA release identity and certification
- The codebase contains `QaReleaseIdentity.releaseTag` and `CrashlyticsVerificationService` wired for RC2.
- The authoritative candidate tag in repo scripts is `yohpal-live-v1.0j-rc2`.
- This report should treat that tag as the official release identity for the current candidate.

## Gap summary
The current code partially implements the requested RC2 delivery, but the following gaps remain:

- Missing explicit `CreatorIdentityBlock` component with safe truncation and VoiceOver semantics.
- Missing structured `CreatorVideoGrid` abstraction and owner-vs-public category transitions.
- Missing creator library category model and tab selector in profile UX.
- Missing server-backed or persisted no-repeat feed exclusion state.
- Missing explicit iOS parity tests for Recommended / Following feed categories.
- Existing feed filtering can produce empty-state behavior due to strict metadata gating.

## Recommended update path

1. Implement `CreatorIdentityBlock` in `apps/mobile_flutter/lib/features/video_feed/widgets/creator_identity_block.dart` and use it in `VideoOverlayWidget` and any creator-card surfaces.
2. Update `CreatorProfileScreen` to use a reusable `CreatorVideoGrid` widget with loading, error, empty, and videos-available states.
3. Add `CreatorLibraryCategory` and `CreatorLibraryTabs` to the creator profile flow, with public-only tabs for visitors and owner-only tabs for the profile owner.
4. Add persistent local no-repeat state in `VideoFeedController` or a dedicated service; persist exclusions across restarts and respect them for automatic feed recommendation.
5. Add a server exposure contract or feed request shape that can accept `excludedVideoIds` and/or a user exposure state.
6. Add explicit widget tests for iOS feed parity and creator identity display.
7. Keep the existing feed category tabs in `VideoFeedScreen` and ensure they remain identical on both platforms.

## Acceptance criteria
- Creator display name appears and truncates safely.
- Username appears in `@username` format.
- Verified badge displays only when `video.ownerVerified` is true.
- Tapping the creator identity opens the correct creator profile.
- Creator profile displays a visible video grid below the header.
- Profile grid renders loading skeleton, error retry, empty state, and videos state.
- Owner-only categories are hidden from visitors and protected by backend access rules.
- Automatic forward recommendations do not repeat recently viewed videos.
- App restart preserves local no-repeat exclusions.
- iOS shows `Recommended` and `Following` tabs with parity to Android.
- Feed category switching loads the correct source.
- The report is aligned to `yohpal-live-v1.0j-rc2`.

## Status
- Implemented today:
  - feed tabs for Recommended / Following / Trending,
  - creator overlay tap-to-profile,
  - profile video grid rendering,
  - basic session-level no-repeat logic in `VideoFeedController`.
- Still required:
  - dedicated creator identity component,
  - creator profile category navigation,
  - persistent cross-device no-repeat handling,
  - explicit iOS parity tests,
  - full release directive compliance with owner/public category rules.

## Recommended filename
`apps/mobile_flutter/docs/YohPal Mobile Flutter — 1.0J-RC2 Creator Profile, Feed Parity & No-Repeat Recovery Report.md`
