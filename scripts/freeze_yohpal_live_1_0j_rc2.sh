#!/usr/bin/env bash
# Freeze YOHPAL LIVE 1.0J-RC2: validate, record git SHA, and stamp evidence.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="$ROOT/release-evidence/yohpal-live-1.0j-rc2"
STAMP_FILE="$EVIDENCE_DIR/20-governance/freeze.json"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  YOHPAL LIVE 1.0J-RC2 — Release Freeze"
echo "═══════════════════════════════════════════════════════"
echo ""

# 1. Run the validator first — freeze is blocked if it fails.
echo "Running validation …"
bash "$ROOT/scripts/validate_yohpal_live_1_0j_rc2.sh"
echo "Validation passed."
echo ""

# 2. Capture the current commit SHA and branch.
GIT_SHA="$(git -C "$ROOT" rev-parse HEAD)"
GIT_BRANCH="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
FREEZE_TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

echo "Branch : $GIT_BRANCH"
echo "SHA    : $GIT_SHA"
echo "Time   : $FREEZE_TS"
echo ""

# 3. Write the governance stamp.
mkdir -p "$(dirname "$STAMP_FILE")"
cat > "$STAMP_FILE" <<JSON
{
  "release": "yohpal-live-1.0j-rc2",
  "frozenAt": "$FREEZE_TS",
  "gitBranch": "$GIT_BRANCH",
  "gitSha": "$GIT_SHA",
  "frozenBy": "$(git -C "$ROOT" config user.email || echo 'unknown')"
}
JSON

echo "Governance stamp written → $STAMP_FILE"
echo ""
echo "RC2 freeze complete.  SHA: $GIT_SHA"
echo ""
