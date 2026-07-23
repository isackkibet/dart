#!/usr/bin/env bash
set -e

echo "Checking Flutter overlay files..."

required_files=(
  "flutter/lib/yohpal_live_streaming.dart"
  "flutter/lib/src/config/yohpal_streaming_config.dart"
  "flutter/lib/src/signaling/yohpal_signal_message.dart"
  "flutter/lib/src/signaling/yohpal_signaling_client.dart"
  "flutter/lib/src/controllers/yohpal_broadcaster_controller.dart"
  "flutter/lib/src/controllers/yohpal_viewer_controller.dart"
  "flutter/lib/src/ui/yohpal_streaming_home_screen.dart"
  "flutter/lib/src/ui/yohpal_broadcaster_screen.dart"
  "flutter/lib/src/ui/yohpal_viewer_screen.dart"
)

for file in "${required_files[@]}"; do
  if [ -f "$file" ]; then
    echo "  $file"
  else
    echo "missing: $file"
    exit 1
  fi
done

echo "Flutter overlay static check passed"
