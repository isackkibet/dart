#!/usr/bin/env bash
set -e

echo "Checking for dangerous foundation overwrite paths..."

dangerous_paths=(
  "lib/main.dart"
  "android/app/src/main/AndroidManifest.xml"
  "ios/Runner/Info.plist"
  "firebase.json"
  "pubspec.yaml"
)

for path in "${dangerous_paths[@]}"; do
  if [ -f "$path" ]; then
    echo " Overlay contains dangerous root app path: $path"
    echo "This overlay must not replace the existing YohPal Live foundation."
    exit 1
  fi
done

echo " No foundation overwrite paths detected inside overlay"
