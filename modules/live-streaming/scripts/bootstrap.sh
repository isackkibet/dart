#!/usr/bin/env bash
set -e

echo "Bootstrapping YohPal Live Streaming Overlay..."

if [ ! -f ".env" ]; then
  echo "Creating .env from .env.example"
  cp .env.example .env
fi

if command -v npm >/dev/null 2>&1; then
  npm install
else
  echo "npm not found. Install Node.js first."
  exit 1
fi

if [ -d "server/mediasoup" ]; then
  (
    cd server/mediasoup
    npm install
  )
fi

bash scripts/generate-turn-config.sh

echo "Bootstrap complete."
echo "Next: edit .env and set ANNOUNCED_IP/LAN_IP to your machine LAN IP."
