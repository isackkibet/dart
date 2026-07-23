#!/usr/bin/env bash
set -e

required_files=(
  "README.md"
  ".env.example"
  "package.json"
  "docs/MASTER_BLUEPRINT.md"
  "docs/MERGE_GUIDE.md"
  "docs/LOCAL_DOCKER_WORKFLOW.md"
  "docs/SMOKE_TEST_CHECKLIST.md"
  "docker/docker-compose.yml"
  "docker/nginx/default.conf"
  "docker/turn/turnserver.conf"
  "server/mediasoup/package.json"
  "server/mediasoup/Dockerfile"
  "server/mediasoup/src/server.js"
  "server/mediasoup/src/config.js"
  "server/mediasoup/src/workerManager.js"
  "server/mediasoup/src/room.js"
  "server/mediasoup/src/roomRegistry.js"
  "server/mediasoup/src/peer.js"
  "server/mediasoup/src/transportFactory.js"
  "server/mediasoup/src/httpServer.js"
  "server/mediasoup/src/signaling/signalingServer.js"
  "server/mediasoup/src/signaling/handlers.js"
  "server/mediasoup/src/signaling/messages.js"
  "server/mediasoup/src/signaling/auth.js"
  "server/mediasoup/src/signaling/broadcast.js"
  "flutter/README.md"
  "flutter/lib/yohpal_live_streaming.dart"
  "flutter/lib/src/config/yohpal_streaming_config.dart"
  "flutter/lib/src/signaling/yohpal_signal_message.dart"
  "flutter/lib/src/signaling/yohpal_signaling_client.dart"
  "flutter/lib/src/controllers/yohpal_broadcaster_controller.dart"
  "flutter/lib/src/controllers/yohpal_viewer_controller.dart"
  "flutter/lib/src/ui/yohpal_streaming_home_screen.dart"
  "flutter/lib/src/ui/yohpal_broadcaster_screen.dart"
  "flutter/lib/src/ui/yohpal_viewer_screen.dart"
  "test-client/index.html"
)

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo " Missing required file: $file"
    exit 1
  fi
done

echo " Required file validation passed"
