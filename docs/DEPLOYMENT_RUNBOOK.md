# YohPal Live Deployment Runbook
## Preflight
```bash
cd apps/yohpal_live
flutter pub get
flutter analyze
flutter test
cd ../../backend/firebase_functions
npm install
npm run build
npm test
```
### Deploy Firestore
```bash
firebase deploy --only firestore:rules,firestore:indexes
```
### Deploy Functions
```bash
firebase deploy --only functions
```
### Deploy Cloud Run Worker
Use the approved Cloud Run deployment pipeline for the Python FFmpeg worker.
### Go/No-Go
Proceed only if:
- Flutter tests pass
- Functions tests pass
- Firestore rules deployed
- Indexes deployed
- Media worker dispatch test passes
