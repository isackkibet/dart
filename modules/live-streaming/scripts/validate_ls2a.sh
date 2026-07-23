#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_ROOT="${ROOT}/flutter"
SERVER_ROOT="${ROOT}/server"
EVIDENCE_ROOT="${ROOT}/release-evidence/live-streaming-ls2a"

mkdir -p "${EVIDENCE_ROOT}"

echo "LS-2A validation started"
date -u +"%Y-%m-%dT%H:%M:%SZ" \
> "${EVIDENCE_ROOT}/validation-started-at.txt"

git -C "${ROOT}" branch --show-current \
> "${EVIDENCE_ROOT}/branch.txt"

git -C "${ROOT}" rev-parse HEAD \
> "${EVIDENCE_ROOT}/commit.txt"

git -C "${ROOT}" status --short \
> "${EVIDENCE_ROOT}/working-tree-before.txt"

if [[ -n "$(git -C "${ROOT}" status --porcelain)" ]]; then
  echo "FAIL: working tree must be clean before validation."
  exit 10
fi

pushd "${FLUTTER_ROOT}" >/dev/null
flutter clean \
2>&1 | tee "${EVIDENCE_ROOT}/flutter-clean.txt"
flutter pub get \
2>&1 | tee "${EVIDENCE_ROOT}/flutter-pub-get.txt"
dart format \
--output=none \
--set-exit-if-changed \
lib test \
2>&1 | tee "${EVIDENCE_ROOT}/dart-format.txt"
flutter analyze \
2>&1 | tee "${EVIDENCE_ROOT}/flutter-analyze.txt"
flutter test \
--reporter expanded \
2>&1 | tee "${EVIDENCE_ROOT}/flutter-test.txt"
popd >/dev/null

pushd "${SERVER_ROOT}" >/dev/null
npm ci \
2>&1 | tee "${EVIDENCE_ROOT}/server-npm-ci.txt"
npm test \
2>&1 | tee "${EVIDENCE_ROOT}/server-test.txt"
popd >/dev/null

git -C "${ROOT}" status --short \
> "${EVIDENCE_ROOT}/working-tree-after.txt"

if [[ -n "$(git -C "${ROOT}" status --porcelain)" ]]; then
  echo "FAIL: validation changed the working tree."
  exit 11
fi

grep -q "No issues found" \
"${EVIDENCE_ROOT}/flutter-analyze.txt"
grep -q "LS2A-UI-12" \
"${EVIDENCE_ROOT}/flutter-test.txt"
grep -q "LS2A-UI-13" \
"${EVIDENCE_ROOT}/flutter-test.txt"

date -u +"%Y-%m-%dT%H:%M:%SZ" \
> "${EVIDENCE_ROOT}/validation-completed-at.txt"

echo "PASS: LS-2A Flutter and server validation completed."
