#!/usr/bin/env bash
set -e

if [ ! -f ".env" ]; then
  echo ".env missing."
  exit 1
fi

set -a
source .env
set +a

LAN_IP="${LAN_IP:-127.0.0.1}"

echo "Checking HTTPS health endpoint..."
curl -k "https://${LAN_IP}/health"
echo ""

echo "Checking test client endpoint..."
curl -k -I "https://${LAN_IP}/test-client/"
echo ""

echo "Endpoint checks complete."
