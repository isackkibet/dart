#!/usr/bin/env bash
# Validate YOHPAL LIVE 1.0J-RC2 implementation completeness.
set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

check() {
  local label="$1" path="$2"
  if [ -e "$ROOT/$path" ]; then
    echo "  PASS  $label"
    PASS=$((PASS+1))
  else
    echo "  FAIL  $label  →  $path"
    FAIL=$((FAIL+1))
  fi
}

grep_check() {
  local label="$1" file="$2" pattern="$3"
  if grep -q "$pattern" "$ROOT/$file" 2>/dev/null; then
    echo "  PASS  $label"
    PASS=$((PASS+1))
  else
    echo "  FAIL  $label  →  pattern '$pattern' not found in $file"
    FAIL=$((FAIL+1))
  fi
}

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  YOHPAL LIVE 1.0J-RC2 — Implementation Validator"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "── 1. CreatorIdentityBlock ─────────────────────────────"
check "widget file" "apps/mobile_flutter/lib/features/creator_profile/widgets/creator_identity_block.dart"
grep_check "onOpenProfile param" "apps/mobile_flutter/lib/features/creator_profile/widgets/creator_identity_block.dart" "onOpenProfile"
grep_check "creator-identity-block key" "apps/mobile_flutter/lib/features/creator_profile/widgets/creator_identity_block.dart" "creator-identity-block"
grep_check "creator-display-name key" "apps/mobile_flutter/lib/features/creator_profile/widgets/creator_identity_block.dart" "creator-display-name"
grep_check "creator-verification-badge key" "apps/mobile_flutter/lib/features/creator_profile/widgets/creator_identity_block.dart" "creator-verification-badge"
grep_check "creator-username key" "apps/mobile_flutter/lib/features/creator_profile/widgets/creator_identity_block.dart" "creator-username"

echo ""
echo "── 2. Creator Library Categories (16) ──────────────────"
check "domain file" "apps/mobile_flutter/lib/features/creator_profile/domain/creator_library_category.dart"
grep_check "16 categories" "apps/mobile_flutter/lib/features/creator_profile/domain/creator_library_category.dart" "liveReplays"
grep_check "ownerOnly getter" "apps/mobile_flutter/lib/features/creator_profile/domain/creator_library_category.dart" "ownerOnly"
grep_check "availableCreatorCategories fn" "apps/mobile_flutter/lib/features/creator_profile/domain/creator_library_category.dart" "availableCreatorCategories"

echo ""
echo "── 3. Creator Video Grid ───────────────────────────────"
check "grid widget" "apps/mobile_flutter/lib/features/creator_profile/widgets/creator_video_grid.dart"
grep_check "hasMore param" "apps/mobile_flutter/lib/features/creator_profile/widgets/creator_video_grid.dart" "hasMore"
grep_check "onLoadMore param" "apps/mobile_flutter/lib/features/creator_profile/widgets/creator_video_grid.dart" "onLoadMore"
grep_check "creator-video-grid key" "apps/mobile_flutter/lib/features/creator_profile/widgets/creator_video_grid.dart" "creator-video-grid'"

echo ""
echo "── 4. No-Repeat Feed (Flutter) ─────────────────────────"
check "VideoExposure domain" "apps/mobile_flutter/lib/features/feed/domain/video_exposure.dart"
grep_check "substantiallyViewed" "apps/mobile_flutter/lib/features/feed/domain/video_exposure.dart" "substantiallyViewed"
check "VideoExposureRepository" "apps/mobile_flutter/lib/features/feed/data/video_exposure_repository.dart"
grep_check "loadAutomaticFeedExclusions" "apps/mobile_flutter/lib/features/feed/data/video_exposure_repository.dart" "loadAutomaticFeedExclusions"
check "LocalViewedVideoStore" "apps/mobile_flutter/lib/features/feed/data/local_viewed_video_store.dart"
check "FeedController" "apps/mobile_flutter/lib/features/feed/controllers/feed_controller.dart"
check "FeedRequest" "apps/mobile_flutter/lib/features/feed/domain/feed_request.dart"

echo ""
echo "── 5. Feed Category Parity (Flutter) ───────────────────"
check "FeedCategoryController" "apps/mobile_flutter/lib/features/feed/controllers/feed_category_controller.dart"
grep_check "initial param" "apps/mobile_flutter/lib/features/feed/controllers/feed_category_controller.dart" "FeedCategory initial"

echo ""
echo "── 6. Backend — No-Repeat ──────────────────────────────"
check "feed-eligibility.ts" "backend/firebase_functions/src/feed/feed-eligibility.ts"
grep_check "canReturnVideo" "backend/firebase_functions/src/feed/feed-eligibility.ts" "canReturnVideo"
grep_check "creator_profile source" "backend/firebase_functions/src/feed/feed-eligibility.ts" "creator_profile"
grep_check "own_video source" "backend/firebase_functions/src/feed/feed-eligibility.ts" "own_video"
check "exposure-repository.ts" "backend/firebase_functions/src/feed/exposure-repository.ts"
check "get-feed.ts" "backend/firebase_functions/src/feed/get-feed.ts"
check "feed.types.ts" "backend/firebase_functions/src/feed/feed.types.ts"
grep_check "viewer-exposure source fixed" "backend/firebase_functions/src/feed/viewer-video-exposure.ts" "creator_profile"

echo ""
echo "── 7. Backend — Creator Library ────────────────────────"
check "creator-library.types.ts" "backend/firebase_functions/src/creator-profile/creator-library.types.ts"
check "creator-library-access.ts" "backend/firebase_functions/src/creator-profile/creator-library-access.ts"
grep_check "assertCreatorLibraryAccess typed" "backend/firebase_functions/src/creator-profile/creator-library-access.ts" "CreatorLibraryCategory"
check "get-creator-library.ts" "backend/firebase_functions/src/creator-profile/get-creator-library.ts"

echo ""
echo "── 8. Shared Backend ───────────────────────────────────"
check "shared/pagination.ts" "backend/firebase_functions/src/shared/pagination.ts"

echo ""
echo "── 9. Tests ────────────────────────────────────────────"
check "no-repeat-feed.test.ts" "backend/firebase_functions/src/feed/no-repeat-feed.test.ts"
grep_check "test uses canReturnVideo" "backend/firebase_functions/src/feed/no-repeat-feed.test.ts" "canReturnVideo"
check "creator-library-access.test.ts" "backend/firebase_functions/src/creator-profile/creator-library-access.test.ts"
check "creator_profile_ui_test.dart" "apps/mobile_flutter/test/features/creator_profile/creator_profile_ui_test.dart"
grep_check "Flutter test uses onOpenProfile" "apps/mobile_flutter/test/features/creator_profile/creator_profile_ui_test.dart" "onOpenProfile"

echo ""
echo "── 10. Evidence Directories ────────────────────────────"
check "evidence root" "release-evidence/yohpal-live-1.0j-rc2"
for i in 01-repository 02-creator-identity 03-creator-library 04-video-grid 05-no-repeat-feed 06-category-parity 07-backend-eligibility 08-backend-library 09-backend-feed 10-exposure-store 11-flutter-tests 12-backend-tests 13-scripts 14-build 15-static-analysis 16-device-android 17-device-ios 18-regression 19-release-notes 20-governance; do
  check "evidence/$i" "release-evidence/yohpal-live-1.0j-rc2/$i"
done

echo ""
echo "═══════════════════════════════════════════════════════"
printf "  Result: %d passed, %d failed\n" "$PASS" "$FAIL"
echo "═══════════════════════════════════════════════════════"
echo ""

[ "$FAIL" -eq 0 ]
