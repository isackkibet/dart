#!/usr/bin/env bash
set -euo pipefail

FEATURE_BRANCH="feature/yohpal-live-1.0j"
RELEASE_BRANCH="release/yohpal-live-1.0j-rc1"
TAG="yohpal-live-v1.0j-rc1"

if [[ "$(git branch --show-current)" != "${FEATURE_BRANCH}" ]]; then
  echo "FAIL: must be on ${FEATURE_BRANCH}. Current: $(git branch --show-current)"
  exit 20
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "FAIL: working tree is not clean."
  exit 21
fi

bash "$(git rev-parse --show-toplevel)/scripts/validate_yohpal_live_1_0j_rc1.sh"

git checkout -b "${RELEASE_BRANCH}"

COMMIT="$(git rev-parse HEAD)"

git tag -a "${TAG}" \
  -m "YohPal Live Release 1.0J-RC1
Commit: ${COMMIT}
Scope: immersive feed, engagement integrity and minor safety
Rollout: allow-listed
Unrelated features: frozen"

git show \
  --no-patch \
  --format=fuller \
  "${TAG}"

echo "PASS: immutable candidate frozen."
echo "Commit: ${COMMIT}"
echo "Tag:    ${TAG}"
