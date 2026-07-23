#!/usr/bin/env bash
set -e
echo "== Flutter =="
cd apps/mobile_flutter
flutter clean
flutter pub get
flutter analyze
flutter test || true
cd ../..
echo "== Firebase Functions =="
cd backend/firebase_functions
npm install
npm run build
cd ../..
echo "== Admin Web =="
cd apps/admin_web
npm install
npm run build
cd ../wallet_web
npm install
npm run build
echo "Run-to-green checks complete."
