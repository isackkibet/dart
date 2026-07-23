# Conflict Resolution Register

| Conflict | Resolution |
|---|---|
| Temporary owner IDs in Flutter | Replaced by Firebase ID token; owner UID is derived server-side. |
| In-memory production and audit stores | Replaced in production by Firestore repository; memory adapter retained only for tests. |
| Mesh control attempting to own media | Mediasoup remains canonical media plane; Mesh sends authenticated program-layout instructions only. |
| Duplicate viewer composition | Canonical program state is stored in the SFU room and broadcast to clients for deterministic rendering. |
| Unprotected control endpoints | All owner mutations and reads now require Firebase authorization and owner match. |
| Broken Mesh Dockerfile paths | Build context corrected to the live-streaming module root with contracts included. |
