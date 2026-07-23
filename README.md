# YohPal Live v2 — Full Firebase + Flutter Implementation Pack

This pack is the clean rebuild baseline for YohPal Live v2. It is intentionally modular so developers stop mixing manual code into old files.

## Apps
- `apps/mobile_flutter` — Flutter mobile app starter.
- `apps/admin_web` — Next.js admin dashboard starter.
- `apps/wallet_web` — Next.js web wallet starter.

## Backend
- `backend/firebase_functions` — Firebase Functions TypeScript starter.
- `backend/cloud_run_workers` — Python Cloud Run workers for transcoding, AI video jobs, multistream relay, and search indexing.
- `backend/shared_contracts` — shared event names and schemas.

## Firebase
- `firestore/rules/firestore.rules`
- `firestore/indexes/firestore.indexes.json`

## Scripts
- `scripts/run_to_green.sh`
- `scripts/setup_local.sh`

## Build Rule
Every feature must follow:

Model → Repository → Service → Controller → UI Adapter → Screen/Widget → Rules → Tests → Analytics Events
