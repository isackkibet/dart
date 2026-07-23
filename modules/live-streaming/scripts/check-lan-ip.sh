#!/usr/bin/env bash
set -e

if [ ! -f ".env" ]; then
  echo ".env missing."
  exit 1
fi

set -a
source .env
set +a

if [ -z "$LAN_IP" ] || [ -z "$ANNOUNCED_IP" ]; then
  echo "LAN_IP or ANNOUNCED_IP missing in .env"
  exit 1
fi

if [ "$LAN_IP" = "127.0.0.1" ] || [ "$ANNOUNCED_IP" = "127.0.0.1" ]; then
  echo "WARNING: 127.0.0.1 only works for same-machine browser testing."
  echo "For physical Android/iOS devices, use the host machine LAN IP."
fi

echo "Configured LAN_IP: $LAN_IP"
echo "Configured ANNOUNCED_IP: $ANNOUNCED_IP"
echo ""
echo "Local IPv4 addresses detected:"

if command -v ip >/dev/null 2>&1; then
  ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true
elif command -v ifconfig >/dev/null 2>&1; then
  ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | awk '{print $2}' | sed 's/addr://g' || true
else
  echo "Could not auto-detect local IP addresses."
fi
