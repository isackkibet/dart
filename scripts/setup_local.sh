#!/usr/bin/env bash
set -e
cd apps/mobile_flutter && flutter pub get || true
cd ../../backend/firebase_functions && npm install || true
cd ../../apps/admin_web && npm install || true
cd ../wallet_web && npm install || true
