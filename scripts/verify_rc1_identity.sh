#!/usr/bin/env bash
# verify_rc1_identity.sh — RC1 repository identity verification
#
# Produces a repo-report.md in the evidence directory and exits 0 only when
# the repository is in the exact state required for RC1 submission:
#   • On branch  release/yohpal-live-1.0g-rc1
#   • Tagged     yohpal-live-v1.0.0-rc1  at HEAD
#   • Clean working tree (no uncommitted changes)
#
# Usage (run from repo root):
#   bash scripts/verify_rc1_identity.sh [--allow-dirty] [--report-dir <path>]
#
#   --allow-dirty   Skip the clean-tree check (useful during evidence assembly
#                   before the final freeze commit).
#   --report-dir    Directory to write repo-report.md (default:
#                   apps/mobile_flutter/release-evidence/yohpal-live-1.0g-rc1/repo-identity)

set -euo pipefail

EXPECTED_BRANCH="release/yohpal-live-1.0g-rc1"
EXPECTED_TAG="yohpal-live-v1.0.0-rc1"
DEFAULT_REPORT_DIR="apps/mobile_flutter/release-evidence/yohpal-live-1.0g-rc1/repo-identity"

ALLOW_DIRTY=false
REPORT_DIR="$DEFAULT_REPORT_DIR"

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --allow-dirty)  ALLOW_DIRTY=true; shift ;;
    --report-dir)   REPORT_DIR="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 64 ;;
  esac
done

# ── Collect identity ──────────────────────────────────────────────────────────
BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT_SHA=$(git rev-parse HEAD)
COMMIT_SHORT=$(git rev-parse --short HEAD)
COMMIT_DATE=$(git log -1 --format="%ci")
COMMIT_AUTHOR=$(git log -1 --format="%an <%ae>")
COMMIT_MSG=$(git log -1 --format="%s")
TAG_AT_HEAD=$(git tag --points-at HEAD 2>/dev/null | tr '\n' ' ' | xargs)
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "(no remote)")
DIRTY=$(git status --porcelain | wc -l | tr -d ' ')
GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ── Validation ────────────────────────────────────────────────────────────────
PASS=true
WARNINGS=()

if [[ "$BRANCH" != "$EXPECTED_BRANCH" ]]; then
  WARNINGS+=("BRANCH MISMATCH: got '$BRANCH', expected '$EXPECTED_BRANCH'")
  PASS=false
fi

if [[ "$TAG_AT_HEAD" != "$EXPECTED_TAG" && "$TAG_AT_HEAD" != *"$EXPECTED_TAG"* ]]; then
  WARNINGS+=("TAG MISSING: '$EXPECTED_TAG' does not point at HEAD (found: '${TAG_AT_HEAD:-none}')")
  PASS=false
fi

if [[ "$ALLOW_DIRTY" == "false" && "$DIRTY" -gt 0 ]]; then
  WARNINGS+=("DIRTY TREE: $DIRTY uncommitted change(s) present")
  PASS=false
fi

# ── Print to stdout ───────────────────────────────────────────────────────────
echo "=== RC1 Repository Identity Verification ==="
echo "Branch:      $BRANCH"
echo "Commit SHA:  $COMMIT_SHA"
echo "Commit date: $COMMIT_DATE"
echo "Tag at HEAD: ${TAG_AT_HEAD:-'(none)'}"
echo "Remote:      $REMOTE_URL"
echo "Dirty files: $DIRTY"
echo ""

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo "WARNINGS:"
  for w in "${WARNINGS[@]}"; do
    echo "  ⚠  $w"
  done
  echo ""
fi

RESULT="PASS"
if [[ "$PASS" == "false" ]]; then RESULT="FAIL (see warnings above)"; fi
echo "Verification result: $RESULT"
echo "Generated at: $GENERATED_AT"

# ── Write report ──────────────────────────────────────────────────────────────
mkdir -p "$REPORT_DIR"

# Plain-text files for evidence archive
echo "$COMMIT_SHA"           > "$REPORT_DIR/commit-sha.txt"
echo "$BRANCH"               > "$REPORT_DIR/branch.txt"
echo "${TAG_AT_HEAD:-none}"  > "$REPORT_DIR/tag.txt"
git log --oneline -20        > "$REPORT_DIR/git-log.txt" 2>/dev/null || true
git log -1 --stat            > "$REPORT_DIR/commit-stat.txt" 2>/dev/null || true

# Human-readable report
cat > "$REPORT_DIR/repo-report.md" <<REPORT
# RC1 Repository Identity Report

**Generated:** $GENERATED_AT
**Verification result:** $RESULT

## Identity

| Field | Value |
|-------|-------|
| Branch | \`$BRANCH\` |
| Full commit SHA | \`$COMMIT_SHA\` |
| Short SHA | \`$COMMIT_SHORT\` |
| Tag at HEAD | \`${TAG_AT_HEAD:-none}\` |
| Commit date | $COMMIT_DATE |
| Author | $COMMIT_AUTHOR |
| Commit message | $COMMIT_MSG |
| Remote | $REMOTE_URL |
| Dirty files | $DIRTY |

## Validation

| Check | Expected | Actual | Result |
|-------|----------|--------|--------|
| Branch | \`$EXPECTED_BRANCH\` | \`$BRANCH\` | $( [[ "$BRANCH" == "$EXPECTED_BRANCH" ]] && echo "PASS" || echo "**FAIL**" ) |
| Tag | \`$EXPECTED_TAG\` | \`${TAG_AT_HEAD:-none}\` | $( [[ "$TAG_AT_HEAD" == *"$EXPECTED_TAG"* ]] && echo "PASS" || echo "**FAIL**" ) |
| Clean tree | 0 changes | $DIRTY change(s) | $( [[ "$DIRTY" -eq 0 ]] && echo "PASS" || ( [[ "$ALLOW_DIRTY" == "true" ]] && echo "SKIPPED (--allow-dirty)" || echo "**FAIL**" ) ) |

## Warnings

$(if [[ ${#WARNINGS[@]} -eq 0 ]]; then echo "None."; else
  for w in "${WARNINGS[@]}"; do echo "- $w"; done
fi)

## Files

- \`commit-sha.txt\` — full 40-character SHA
- \`branch.txt\` — release branch name
- \`tag.txt\` — release tag
- \`git-log.txt\` — last 20 commits
- \`commit-stat.txt\` — HEAD commit stat
REPORT

echo ""
echo "Report written to: $REPORT_DIR/repo-report.md"

if [[ "$PASS" == "false" ]]; then exit 1; fi
