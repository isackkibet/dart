#!/usr/bin/env bash
# validate_zero_wait_1_0h.sh
# Verifies that all 1.0H Zero-Wait files exist and the project analyzes cleanly.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "  [OK]  $path"
    PASS=$((PASS + 1))
  else
    echo "  [MISSING]  $path"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "========================================"
echo "  YohPal Live 1.0H Zero-Wait Validator"
echo "========================================"
echo ""

echo "── Models & Policy ─────────────────────"
check_file "lib/features/feed/zero_wait/models/preload_video.dart"
check_file "lib/features/feed/zero_wait/policy/zero_wait_buffer_policy.dart"

echo ""
echo "── Profiling ───────────────────────────"
check_file "lib/features/feed/zero_wait/profiling/device_capability_profiler.dart"
check_file "lib/features/feed/zero_wait/profiling/smart_network_profiler.dart"

echo ""
echo "── Storage & Data ──────────────────────"
check_file "lib/features/feed/zero_wait/storage/feed_inventory_store.dart"
check_file "lib/features/feed/zero_wait/data/zero_wait_feed_repository.dart"

echo ""
echo "── Cache ───────────────────────────────"
check_file "lib/features/feed/zero_wait/cache/yohpal_video_cache.dart"
check_file "lib/features/feed/zero_wait/cache/warm_media_scheduler.dart"

echo ""
echo "── Telemetry ───────────────────────────"
check_file "lib/features/feed/zero_wait/telemetry/zero_wait_telemetry.dart"

echo ""
echo "── Controllers ─────────────────────────"
check_file "lib/features/feed/zero_wait/controllers/feed_inventory_coordinator.dart"
check_file "lib/features/feed/zero_wait/controllers/zero_wait_playback_controller.dart"

echo ""
echo "── Services & Lifecycle ────────────────"
check_file "lib/features/feed/zero_wait/services/feed_startup_warmup_service.dart"
check_file "lib/features/feed/zero_wait/lifecycle/zero_wait_lifecycle_observer.dart"

echo ""
echo "── Widgets & Presentation ──────────────"
check_file "lib/features/feed/zero_wait/widgets/zero_wait_video_player.dart"
check_file "lib/features/feed/controllers/video_feed_controller.dart"
check_file "lib/features/feed/presentation/video_feed_screen.dart"

echo ""
echo "── Production Upgrades ─────────────────"
check_file "lib/features/video_playback/services/video_media_cache.dart"
check_file "lib/features/video_playback/services/smart_network_profiler.dart"
check_file "lib/features/video_playback/controllers/zero_wait_playback_controller.dart"

echo ""
echo "── Tests ───────────────────────────────"
check_file "test/features/feed/zero_wait/zero_wait_policy_test.dart"
check_file "test/features/feed/zero_wait/feed_inventory_coordinator_test.dart"
check_file "test/features/feed/zero_wait/controller_ceiling_test.dart"
check_file "test/features/feed/zero_wait/startup_warmup_test.dart"

echo ""
echo "── Evidence Directories ────────────────"
for dir in \
  "release-evidence/yohpal-live-1.0h-zero-wait/01-repository" \
  "release-evidence/yohpal-live-1.0h-zero-wait/02-buffer-policy" \
  "release-evidence/yohpal-live-1.0h-zero-wait/03-network-profiler" \
  "release-evidence/yohpal-live-1.0h-zero-wait/04-device-profiler" \
  "release-evidence/yohpal-live-1.0h-zero-wait/05-inventory-coordinator" \
  "release-evidence/yohpal-live-1.0h-zero-wait/06-feed-repository" \
  "release-evidence/yohpal-live-1.0h-zero-wait/07-cache-layer" \
  "release-evidence/yohpal-live-1.0h-zero-wait/08-warm-scheduler" \
  "release-evidence/yohpal-live-1.0h-zero-wait/09-telemetry" \
  "release-evidence/yohpal-live-1.0h-zero-wait/10-playback-controller" \
  "release-evidence/yohpal-live-1.0h-zero-wait/11-startup-warmup" \
  "release-evidence/yohpal-live-1.0h-zero-wait/12-lifecycle-observer" \
  "release-evidence/yohpal-live-1.0h-zero-wait/13-widget-layer" \
  "release-evidence/yohpal-live-1.0h-zero-wait/14-test-results" \
  "release-evidence/yohpal-live-1.0h-zero-wait/15-validation-script" \
  "release-evidence/yohpal-live-1.0h-zero-wait/16-governance"
do
  if [[ -d "$dir" ]]; then
    echo "  [OK]  $dir"
    PASS=$((PASS + 1))
  else
    echo "  [MISSING]  $dir"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "── Dart Analysis ───────────────────────"
if dart analyze lib/ --fatal-infos 2>&1 | grep -E "^(error|warning)" ; then
  echo "  [FAIL] dart analyze found errors"
  FAIL=$((FAIL + 1))
else
  echo "  [OK]  dart analyze lib/ clean"
  PASS=$((PASS + 1))
fi

echo ""
echo "── Unit Tests ──────────────────────────"
if flutter test test/features/feed/zero_wait/ --no-pub 2>&1 | tail -5; then
  echo "  [OK]  flutter test passed"
  PASS=$((PASS + 1))
else
  echo "  [FAIL] flutter test failed"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "========================================"
printf "  Results: %d passed, %d failed\n" "$PASS" "$FAIL"
echo "========================================"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
