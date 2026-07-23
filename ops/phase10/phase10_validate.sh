#!/usr/bin/env bash
set -euo pipefail

echo "PHASE 10 VALIDATION"

echo "Checking Flutter..."
flutter analyze
flutter test

echo "Checking backend..."
cd backend/firebase_functions
npm run build
npm test

echo "Checking Firebase indexes..."
firebase firestore:indexes

echo "Checking Firebase functions..."
firebase functions:list

echo "Validation completed. Attach outputs to Phase 10 report."
