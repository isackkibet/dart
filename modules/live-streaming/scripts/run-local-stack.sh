#!/usr/bin/env bash
set -e

if [ ! -f ".env" ]; then
  echo ".env missing. Creating from .env.example"
  cp .env.example .env
  echo "Edit .env and set ANNOUNCED_IP/LAN_IP before continuing."
  exit 1
fi

if [ ! -f "docker/certs/localhost.crt" ] || [ ! -f "docker/certs/localhost.key" ]; then
  echo "TLS certificate missing. Generating..."
  bash scripts/generate-certs.sh
fi

bash scripts/generate-turn-config.sh
bash scripts/check-lan-ip.sh

npm run docker:up
