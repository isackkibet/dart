#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
EVIDENCE="${ROOT}/release-evidence/yohpal-live-1.0j-rc1"

mkdir -p \
  "${EVIDENCE}/01-repository" \
  "${EVIDENCE}/02-flutter" \
  "${EVIDENCE}/03-functions"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "FAIL: working tree must be clean."
  exit 10
fi

git branch --show-current \
  > "${EVIDENCE}/01-repository/branch.txt"

git rev-parse HEAD \
  > "${EVIDENCE}/01-repository/commit.txt"

pushd "${ROOT}/apps/mobile_flutter" >/dev/null

flutter clean \
  2>&1 | tee "${EVIDENCE}/02-flutter/clean.txt"

flutter pub get \
  2>&1 | tee "${EVIDENCE}/02-flutter/pub-get.txt"

dart format \
  --output=none \
  --set-exit-if-changed \
  lib test \
  2>&1 | tee "${EVIDENCE}/02-flutter/format.txt"

flutter analyze \
  2>&1 | tee "${EVIDENCE}/02-flutter/analyze.txt"

flutter test \
  --reporter expanded \
  2>&1 | tee "${EVIDENCE}/02-flutter/test.txt"

popd >/dev/null

pushd "${ROOT}/backend/firebase_functions" >/dev/null

npm ci \
  2>&1 | tee "${EVIDENCE}/03-functions/npm-ci.txt"

npm run lint \
  2>&1 | tee "${EVIDENCE}/03-functions/lint.txt"

npm run build \
  2>&1 | tee "${EVIDENCE}/03-functions/build.txt"

npm test \
  2>&1 | tee "${EVIDENCE}/03-functions/test.txt"

popd >/dev/null

if [[ -n "$(git status --porcelain)" ]]; then
  echo "FAIL: validation modified the working tree."
  exit 11
fi

echo "PASS: YohPal Live 1.0J-RC1 automated validation completed."
