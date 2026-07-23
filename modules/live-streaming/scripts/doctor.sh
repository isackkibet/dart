#!/usr/bin/env bash
set -e

echo "YohPal Live Streaming Doctor"
echo "----------------------------"

check() {
  local name="$1"
  local cmd="$2"

  if command -v "$cmd" >/dev/null 2>&1; then
    echo "✅ $name found: $(command -v "$cmd")"
  else
    echo "❌ $name missing"
  fi
}

check "Node.js" node
check "npm" npm
check "Docker" docker
check "OpenSSL" openssl
check "curl" curl
check "Flutter" flutter

if docker compose version >/dev/null 2>&1; then
  echo "✅ Docker Compose available"
else
  echo "❌ Docker Compose missing"
fi

echo ""
echo "File checks:"
[ -f ".env" ] && echo "✅ .env exists" || echo "❌ .env missing"
[ -f "docker/docker-compose.yml" ] && echo "✅ docker-compose.yml exists" || echo "❌ docker-compose.yml missing"
[ -f "docker/nginx/default.conf" ] && echo "✅ nginx config exists" || echo "❌ nginx config missing"
[ -f "docker/turn/turnserver.conf" ] && echo "✅ coturn config exists" || echo "❌ coturn config missing"
[ -f "docker/certs/localhost.crt" ] && echo "✅ TLS cert exists" || echo "⚠️  TLS cert missing; run npm run certs"
[ -f "docker/certs/localhost.key" ] && echo "✅ TLS key exists" || echo "⚠️  TLS key missing; run npm run certs"

echo ""
echo "Network checks:"
bash scripts/check-lan-ip.sh || true

echo ""
echo "Required manual checks:"
echo "- Android/iOS device trusts docker/certs/localhost.crt"
echo "- Docker host networking is supported/enabled on your machine"
echo "- Phone and development machine are on the same Wi-Fi network"
