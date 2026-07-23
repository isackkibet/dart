# YohPal Mesh Live v1.0.2 Canonical Integration

## Persistence
The control plane now uses the canonical Firebase/Firestore platform. Production documents are stored in `meshLiveProductions/{productionId}` and immutable audit records in `meshLiveProductions/{productionId}/audit/{eventId}`. `PERSISTENCE_MODE=memory` exists only for isolated tests.

## Identity
Production creation, listing, status, pairing-token issuance, layout mutation and audit access require a verified Firebase ID token. The authenticated UID is the production owner and is never accepted from the request body. Pairing tokens remain short-lived HMAC capability tokens for camera, director and viewer sockets.

## SFU program output
Layout changes are delivered through a private authenticated control-plane call to the canonical mediasoup service. The SFU records the active program layout and broadcasts `program-layout` metadata to connected clients. The current output mode is `CLIENT_COMPOSED_SFU`: viewers consume SFU camera tracks and render SINGLE or SPLIT_SCREEN according to authoritative program metadata. This avoids a duplicate SFU or an unverified transcoding service.

A single server-composited encoded stream is not certified in this release. That requires a separately benchmarked compositor/egress implementation and an ADR if it changes frozen service ownership.

## Security boundaries
- Firebase ID tokens protect owner operations.
- Pairing tokens expire and are scoped to one production, participant and role.
- SFU layout control uses `x-internal-token` and is not public.
- Free plan remains limited to two simultaneously connected cameras and one director.
