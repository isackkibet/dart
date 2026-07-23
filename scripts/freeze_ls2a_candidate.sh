#!/usr/bin/env bash
set -euo pipefail

EXPECTED_SOURCE_BRANCH="${1:-pap1}"
RELEASE_BRANCH="release/yohpal-live-streaming-ls2a-rc1"
RELEASE_TAG="yohpal-live-streaming-ls2a-rc1"

CURRENT_BRANCH="$(git branch --show-current)"

if [[ "${CURRENT_BRANCH}" != "${EXPECTED_SOURCE_BRANCH}" ]]; then
  echo \
    "Expected source branch ${EXPECTED_SOURCE_BRANCH}; found ${CURRENT_BRANCH}"
  exit 1
fi

bash scripts/validate_ls2a.sh

if [[ -n "$(git status --porcelain)" ]]; then
  git checkout -b "${RELEASE_BRANCH}"
  git add \
    modules/live-streaming \
    scripts/validate_ls2a.sh \
    scripts/freeze_ls2a_candidate.sh
  git commit \
    -m "release(streaming): complete LS-2A app-side integration"
else
  git checkout -b "${RELEASE_BRANCH}"
fi

COMMIT_HASH="$(git rev-parse HEAD)"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree remains dirty. Candidate cannot be tagged."
  git status --short
  exit 2
fi

git tag -a "${RELEASE_TAG}" \
  -m "YohPal Live Streaming LS-2A RC1 - ${COMMIT_HASH}"

echo "LS-2A candidate frozen."
echo "Branch: ${RELEASE_BRANCH}"
echo "Commit: ${COMMIT_HASH}"
echo "Tag: ${RELEASE_TAG}"
