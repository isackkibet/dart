#!/usr/bin/env bash
# validate_zero_wait_1_0i_evidence.sh
# Validates that the Zero-Wait 1.0I evidence pack is structurally complete
# and contains no unresolved Critical/P0 defects or pending gates.
#
# Usage: ./scripts/validate_zero_wait_1_0i_evidence.sh [evidence-root]
# Default evidence root: release-evidence/yohpal-live-1.0i
set -euo pipefail

ROOT="${1:-release-evidence/yohpal-live-1.0i}"
MANIFEST="${ROOT}/manifest.json"

required_directories=(
  "01-repository"
  "02-build"
  "03-inventory-runway"
  "04-startup-warmup"
  "05-persistent-cache"
  "06-low-memory-android"
  "07-midrange-android"
  "08-flagship-android"
  "09-older-iphone"
  "10-newer-iphone"
  "11-network-results"
  "12-performance-dashboard"
  "13-crashlytics"
  "14-defects"
  "15-governance"
)

if [[ ! -f "${MANIFEST}" ]]; then
  echo "FAIL: manifest missing at ${MANIFEST}."
  exit 1
fi

for directory in "${required_directories[@]}"; do
  path="${ROOT}/${directory}"
  if [[ ! -d "${path}" ]]; then
    echo "FAIL: missing ${directory}."
    exit 2
  fi
  if [[ -z "$(find "${path}" -type f -print -quit)" ]]; then
    echo "FAIL: ${directory} contains no evidence."
    exit 3
  fi
done

if grep -q '"status": "PENDING"' "${MANIFEST}"; then
  echo "FAIL: mandatory gates remain pending."
  exit 4
fi

if grep -q '"status": "FAIL"' "${MANIFEST}"; then
  echo "FAIL: one or more mandatory gates failed."
  exit 5
fi

commit="$(
  sed -n \
    's/.*"commitHash": *"\([^"]*\)".*/\1/p' \
    "${MANIFEST}" |
  head -n 1
)"
if [[ ! "${commit}" =~ ^[0-9a-f]{40}$ ]]; then
  echo "FAIL: invalid or placeholder commit SHA in manifest."
  exit 6
fi

DEFECTS="${ROOT}/14-defects/defects.csv"
if grep -E \
  ',Critical,P0,.*,(OPEN|TRIAGED|IN PROGRESS|READY FOR RETEST),' \
  "${DEFECTS}" 2>/dev/null; then
  echo "FAIL: unresolved Critical/P0 defect."
  exit 7
fi

echo "PASS: Zero-Wait 1.0I evidence pack is structurally complete."
