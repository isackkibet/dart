#!/usr/bin/env bash
set -euo pipefail

EXPECTED_TAG="yohpal-live-v1.0j-rc2"
EXPECTED_RELEASE_BRANCH="release/yohpal-live-1.0j-rc2"
CURRENT_BRANCH="$(git branch --show-current)"
COMMIT_SHA="$(git rev-parse HEAD)"

if [[ "${CURRENT_BRANCH}" != "${EXPECTED_RELEASE_BRANCH}" ]]; then
  echo "FAIL: expected ${EXPECTED_RELEASE_BRANCH}; found ${CURRENT_BRANCH}"
  exit 10
fi

if [[ ! "${COMMIT_SHA}" =~ ^[0-9a-f]{40}$ ]]; then
  echo "FAIL: full 40-character commit hash is required"
  exit 11
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "FAIL: working tree is not clean"
  git status --short
  exit 12
fi

git tag --points-at HEAD | grep -qx "${EXPECTED_TAG}" || {
  echo "FAIL: ${EXPECTED_TAG} does not point to HEAD"
  exit 13
}

git cat-file -t "${EXPECTED_TAG}" | grep -qx "tag" || {
  echo "FAIL: release tag is not annotated"
  exit 14
}

echo "PASS: immutable RC2 candidate verified"
echo "Commit: ${COMMIT_SHA}"
echo "Tag: ${EXPECTED_TAG}"
