# YohPal Mesh Live v1.0.1 — Canonical Root Merge

## Canonical ownership

- Existing `modules/live-streaming/server/mediasoup` remains the authoritative SFU and media-plane implementation.
- New `modules/live-streaming/server/mesh-control` owns production creation, signed pairing, Free-plan limits, director layout state, reconnect grace and audit events.
- Existing `modules/live-streaming/flutter` remains the authoritative reusable Flutter streaming package. Mesh camera/director UI was merged under `lib/src/mesh_live` and exported by the package entry point.
- The standalone `yohpal_mesh` web repository is retained under `vendor-source/mesh-web` only as a design/source reference. It is not a second runtime or system of record.

## Conflict resolutions

1. Duplicate signaling/media authority: Mesh control forwards SDP/ICE envelopes, while mediasoup remains the media plane. No second SFU was introduced.
2. Duplicate Flutter application: standalone Mesh Flutter files were converted into package features inside the existing streaming module rather than creating another app.
3. Duplicate identity: temporary `ownerId` and actor IDs remain adapter inputs pending canonical Firebase/SSO claims integration.
4. Duplicate persistence: in-memory production and audit stores remain explicitly temporary. Canonical Firestore/PostgreSQL adapters are required before certification.
5. Program output: the existing YohPal Live broadcaster/viewer pipeline remains authoritative; Mesh layout state is now available for compositor integration.

## Run commands

```bash
cd modules/live-streaming/server/mesh-control
npm install
npm test
npm start
```

```bash
cd modules/live-streaming/flutter
flutter pub get
flutter analyze
flutter test
```

## Certification boundary

This merge is a source-level integration candidate. Physical-device WebRTC, TURN fallback, SFU program composition and protected CI remain mandatory before PASS.
