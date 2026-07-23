#!/usr/bin/env bash
set -euo pipefail

echo "Checking RC1 release freeze..."

if [[ -n "$(git status --porcelain)" ]]; then
  echo "FAIL: Working tree contains uncommitted changes."
  exit 1
fi

echo "PASS: Working tree clean."
git rev-parse HEAD
git tag --points-at HEAD
