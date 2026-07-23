# Final Developer Instructions

## Build & Test
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

## Deploy
```bash
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
```

## Feature Flags
| Flag | Purpose |
|---|---|
| `YOHPAL_MULTISTREAM_PILOT` | Enable multistream pilot |
| `YOHPAL_GIFTS_ENABLED` | Enable gift transactions |
| `YOHPAL_FFMPEG_ENABLED` | Enable FFmpeg pipeline |
| `YOHPAL_IOS_PIP_ENABLED` | Enable iOS Picture-in-Picture |
| `YOHPAL_CONTEXTUAL_PIP_ENABLED` | Enable contextual PiP actions |

## Key Paths
- Flutter app: `apps/yohpal_live/`
- Cloud Functions: `backend/firebase_functions/`
- Platform layer: `apps/yohpal_live/lib/platform/`
- PiP features: `apps/yohpal_live/lib/features/pip/`
- Handover docs: `docs/`

## Rules
1. Do not rename working modules before production unless a real runtime defect exists.
2. Document deviations in `docs/MERGE_MAP.md`.
3. All new features launch behind feature flags.
4. Route wallet credits/debits through backend Cloud Functions only.
5. All AI calls route through `YohPalBrainGateway`.
