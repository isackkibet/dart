#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="modules/live-streaming/flutter"
EVIDENCE_DIR="release-evidence/live-streaming-ls2a"

mkdir -p "${EVIDENCE_DIR}"

pushd "${MODULE_DIR}" >/dev/null

flutter clean

flutter pub get \
  | tee "../../../${EVIDENCE_DIR}/flutter-pub-get.txt"

dart format \
  --output=none \
  --set-exit-if-changed \
  lib test \
  | tee "../../../${EVIDENCE_DIR}/dart-format.txt"

flutter analyze \
  | tee "../../../${EVIDENCE_DIR}/flutter-analyze.txt"

flutter test \
  | tee "../../../${EVIDENCE_DIR}/flutter-test.txt"

popd >/dev/null

pushd "modules/live-streaming/server" >/dev/null

npm ci \
  | tee "../../../${EVIDENCE_DIR}/server-npm-ci.txt"

npm test \
  | tee "../../../${EVIDENCE_DIR}/server-tests.txt"

popd >/dev/null

echo "LS-2A source validation completed."
