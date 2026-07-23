#!/usr/bin/env bash
set -e

echo "Running YohPal Live Streaming validation tests..."
echo ""

echo "1. Root doctor"
bash scripts/doctor.sh || true
echo ""

echo "2. Node server tests"
(
  cd server/mediasoup
  npm run test:smoke
  npm run test:contract
)
echo ""

echo "3. Docker compose config check"
docker compose -f docker/docker-compose.yml --env-file .env config >/tmp/yohpal-live-streaming-compose.yml
echo "docker compose config valid"
echo ""

echo "4. Flutter static checklist"
bash scripts/flutter-static-check.sh
echo ""

echo "Validation test pass completed."
