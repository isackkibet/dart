# Overlap and Dependency Map

| Capability | Existing canonical component | Imported source | Resolution |
|---|---|---|---|
| WebRTC/SFU | `server/mediasoup` | Mesh v1 API signaling | Keep mediasoup authoritative; retain control-plane signaling envelopes |
| TURN/STUN | `docker/turn` and module environment | Pack STUN config | Keep canonical TURN deployment; pack config becomes fallback only |
| Flutter live client | `flutter/` package | Pack camera/director screens | Merge screens under `src/mesh_live` |
| Production session | Existing room registry | Pack production store | Separate control state from SFU room state; adapter required |
| Authentication | YohPal Firebase identity | HMAC pairing tokens | HMAC tokens retained for device pairing; issuance must require canonical user auth |
| Audit | Platform audit conventions | In-memory audit | Preserve event contract; replace storage before certification |
| Web UI | Existing admin/mobile apps | standalone Mesh Next.js | Preserve as vendor source only; do not run duplicate app |
