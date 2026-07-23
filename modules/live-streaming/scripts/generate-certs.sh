#!/usr/bin/env bash
set -e

mkdir -p docker/certs

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout docker/certs/localhost.key \
  -out docker/certs/localhost.crt \
  -days 365 \
  -subj "/CN=localhost"

echo "Generated:"
echo "docker/certs/localhost.crt"
echo "docker/certs/localhost.key"
