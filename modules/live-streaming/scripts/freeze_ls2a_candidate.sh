#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEATURE_BRANCH="feature/yohpal-live-streaming-ls2a"
RELEASE_BRANCH="release/yohpal-live-streaming-ls2a-rc1"
TAG="yohpal-live-streaming-ls2a-rc1"

CURRENT_BRANCH="$(git -C "${ROOT}" branch --show-current)"

if [[ "${CURRENT_BRANCH}" != "${FEATURE_BRANCH}" ]]; then
  echo "FAIL: expected ${FEATURE_BRANCH}; found ${CURRENT_BRANCH}."
  exit 20
fi

if [[ -n "$(git -C "${ROOT}" status --porcelain)" ]]; then
  echo "FAIL: working tree is not clean."
  git -C "${ROOT}" status --short
  exit 21
fi

bash "${ROOT}/scripts/validate_ls2a.sh"

if git -C "${ROOT}" show-ref \
  --verify \
  --quiet \
  "refs/heads/${RELEASE_BRANCH}"; then
  echo "FAIL: release branch already exists."
  exit 22
fi

if git -C "${ROOT}" show-ref \
  --verify \
  --quiet \
  "refs/tags/${TAG}"; then
  echo "FAIL: tag already exists."
  exit 23
fi

git -C "${ROOT}" checkout -b "${RELEASE_BRANCH}"

COMMIT="$(git -C "${ROOT}" rev-parse HEAD)"

git -C "${ROOT}" tag -a "${TAG}" \
  -m "YohPal Live Streaming LS-2A RC1

Commit: ${COMMIT}
Scope: final app-side wiring, chat, trusted gifting, coordinator tests,
signaling timeout validation, UI failure-path tests and release freeze."

git -C "${ROOT}" show \
  --no-patch \
  --decorate \
  "${TAG}"

echo
echo "PASS: immutable LS-2A candidate frozen."
echo "Release branch: ${RELEASE_BRANCH}"
echo "Commit: ${COMMIT}"
echo "Annotated tag: ${TAG}"
