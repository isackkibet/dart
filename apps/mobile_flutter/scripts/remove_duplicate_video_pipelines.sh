#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Checking references before deletion..."

if grep -R \
  --exclude-dir=.dart_tool \
  --exclude-dir=build \
  --exclude-dir=.git \
  "core/video/" lib test 2>/dev/null | grep -v "^lib/core/video/"; then
  echo "References to lib/core/video remain. Aborting."
  exit 1
fi

if grep -R \
  --exclude-dir=.dart_tool \
  --exclude-dir=build \
  --exclude-dir=.git \
  "core/video_feed/" lib test 2>/dev/null | grep -v "^lib/core/video_feed/"; then
  echo "References to lib/core/video_feed remain. Aborting."
  exit 1
fi

rm -rf lib/core/video
rm -rf lib/core/video_feed

dart format lib test
flutter analyze
flutter test

echo "Duplicate video pipelines removed successfully."
