#!/usr/bin/env bash
set -euo pipefail

echo "YOHPAL LIVE PHASE 10 — CONTROLLED PRODUCTION ROLLOUT"

echo "Gate 1: Deploy Firestore indexes"
firebase deploy --only firestore:indexes

echo "Gate 2: Deploy Firestore rules"
firebase deploy --only firestore:rules

echo "Gate 3: Build backend"
cd backend/firebase_functions
npm install
npm run build
npm test

echo "Gate 4: Deploy Cloud Functions"
firebase deploy --only functions
cd ../../

echo "Gate 5: Flutter certification"
flutter clean
flutter pub get
flutter analyze
flutter test

echo "Gate 6: Build Android release"
flutter build appbundle --release

echo "Gate 7: Build Web release"
flutter build web --release

echo "Phase 10 rollout build completed successfully."
