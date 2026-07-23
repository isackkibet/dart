#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../apps/mobile_flutter"

echo "======================================================================"
echo "  YohPal Live 1.0H — Zero-Wait 100-Video Buffer Recovery Validation"
echo "======================================================================"
echo ""

cd "$APP_DIR"

echo "--- [1/5] flutter clean ---"
flutter clean

echo ""
echo "--- [2/5] flutter pub get ---"
flutter pub get

echo ""
echo "--- [3/5] dart format (check) ---"
dart format --set-exit-if-changed \
  lib/features/feed/zero_wait/ \
  lib/features/feed/controllers/ \
  lib/features/feed/presentation/ \
  test/zero_wait/ \
  2>&1 || { echo "[WARN] dart format found formatting issues — run 'dart format' to fix"; }

echo ""
echo "--- [4/5] flutter analyze (zero-wait layer only) ---"
flutter analyze \
  lib/features/feed/zero_wait/ \
  lib/features/feed/controllers/ \
  lib/features/feed/presentation/ \
  --no-fatal-infos

echo ""
echo "--- [5/5] flutter test ---"
flutter test test/zero_wait/ --reporter=expanded

echo ""
echo "======================================================================"
echo "  Validation PASSED"
echo "======================================================================"
