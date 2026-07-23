#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-release-evidence/yohpal-live-1.0j-rc2-certification}"
MANIFEST="${ROOT}/manifest.json"

REQUIRED_DIRECTORIES=(
  "01-candidate-identity"
  "02-android-build"
  "03-ios-build"
  "04-creator-identity"
  "05-profile-grid"
  "06-category-access"
  "07-recommended-100"
  "08-following-100"
  "09-restart-persistence"
  "10-cross-device"
  "11-intentional-replay"
  "12-ios-parity"
  "13-android-parity"
  "14-immersive-regression"
  "15-engagement-regression"
  "16-minor-safety"
  "17-accessibility"
  "18-crashlytics"
  "19-security"
  "20-defects"
  "21-governance"
)

[[ -f "${MANIFEST}" ]] || {
  echo "FAIL: manifest.json is missing"
  exit 20
}

for directory in "${REQUIRED_DIRECTORIES[@]}"; do
  path="${ROOT}/${directory}"
  [[ -d "${path}" ]] || {
    echo "FAIL: missing ${directory}"
    exit 21
  }
  [[ -n "$(find "${path}" -type f -print -quit)" ]] || {
    echo "FAIL: ${directory} has no evidence"
    exit 22
  }
done

if grep -q '"PENDING"' "${MANIFEST}"; then
  echo "FAIL: certification gates remain pending"
  exit 23
fi

python3 scripts/certification/check_feed_duplicates.py \
  "${ROOT}/07-recommended-100/feed-sequence.csv"

python3 scripts/certification/check_feed_duplicates.py \
  "${ROOT}/08-following-100/feed-sequence.csv"

# Inverted check: awk exits 0 (success) when unresolved Critical/P0 defects
# exist, which causes the outer 'if' branch to fire and fail the script.
if awk -F',' '
  NR > 1 &&
  ($7 == "Critical" || $8 == "P0") &&
  ($10 == "OPEN" ||
   $10 == "TRIAGED" ||
   $10 == "IN PROGRESS" ||
   $10 == "READY FOR RETEST") {
    print;
    found = 1;
  }
  END {
    exit found ? 0 : 1;
  }
' "${ROOT}/20-defects/defects.csv"; then
  echo "FAIL: unresolved Critical or P0 defect"
  exit 24
fi

echo "PASS: RC2 certification evidence is structurally complete"
