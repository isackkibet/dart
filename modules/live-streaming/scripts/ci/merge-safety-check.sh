#!/usr/bin/env bash
set -e

echo "Running merge safety check..."

blocked_paths=(
  "../../lib/main.dart"
  "../../android/app/src/main/AndroidManifest.xml"
  "../../ios/Runner/Info.plist"
)

for path in "${blocked_paths[@]}"; do
  if [ -f "$path" ]; then
    echo " Existing app file present: $path"
    echo "This is allowed, but this overlay must not overwrite it."
  fi
done

if grep -R "Do not replace" docs README.md flutter/README.md >/dev/null 2>&1; then
  echo " Non-replacement guidance present"
else
  echo " Non-replacement guidance missing"
  exit 1
fi

if grep -R "ANNOUNCED_IP" docs .env.example docker server >/dev/null 2>&1; then
  echo " ANNOUNCED_IP guidance present"
else
  echo " ANNOUNCED_IP guidance missing"
  exit 1
fi

if grep -R "127.0.0.1 only works" docs README.md docker server >/dev/null 2>&1; then
  echo " localhost warning present"
else
  echo "⚠ localhost warning not found; ensure LAN IP warning exists"
fi

echo " Merge safety check passed"
