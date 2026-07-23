# Mesh + Live Integration Diagnostic Report

## Architecture: How Mesh and Live Are Combined

Mesh and Live are **two parallel streaming tiers** that share a codebase but use different transport paths, with a bridge at the "Take Live" moment:

```
┌──────────────────────────────────────────────────────────────┐
│                   MESH TIER (P2P)                            │
│                                                              │
│  Camera Phone 1 ──WebRTC──┐                                  │
│                            ├──Director Console──┐            │
│  Camera Phone 2 ──WebRTC──┘   (Flutter)         │            │
│                                                 │            │
│  ┌─ Socket.IO relay (SDP/ICE via mesh-control) ─┘            │
│  │  QR pairing with HMAC-signed tokens                       │
│  └─────────────────────────────────────────────────────────┘  │
│                               │                               │
│                    "Take Live" button                         │
│                               │                               │
│                               ▼                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              LIVE TIER (SFU Broadcast)                   │  │
│  │                                                          │  │
│  │  mesh-control → HTTP PUT → mediasoup SFU → Viewers      │  │
│  │  (sfuProgramAdapter)    (room program)   (WebRTC)       │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                              │
│  There is also a separate LiveKit-based streaming path:      │
│  Firebase Function → LiveKit token → LiveStreamController    │
└──────────────────────────────────────────────────────────────┘
```

### Code Sharing

Both tiers live inside the same Flutter package at `modules/live-streaming/flutter/`, exported as `yohpal_live_streaming`. The mobile app (`apps/mobile_flutter`) imports this library and registers both sets of routes:

| Route | Screen | Tier |
|---|---|---|
| `/mesh-live` | `HomePage` | Mesh |
| `/mesh-live/create` | `DirectorSetupPage` | Mesh |
| `/mesh-live/join-camera` | `CameraJoinPage` | Mesh |
| `/go-live` | `GoLiveScreen` | Live (traditional) |
| `/live-viewer` | `LiveViewerScreen` | Live (traditional) |

### The Bridge

When the director hits "Take Live", `DirectorConsolePage` calls `MeshApi().setLayout()` which triggers the mesh-control server to push the program layout to the mediasoup SFU via `sfuProgramAdapter.ts`. The SFU then broadcasts the composed program to viewers via its own WebSocket signaling — this is the single point where the two tiers connect.

### Key Architectural Difference

| Aspect | Mesh Tier | Live Tier |
|---|---|---|
| Transport | Direct P2P WebRTC (relayed via Socket.IO) | SFU (mediasoup or LiveKit) |
| Camera→Director | Peer connection, no SFU | N/A (single broadcaster) |
| Director→Viewers | Via mediasoup bridge | SFU fan-out |
| Pairing | QR codes with HMAC-signed tokens | Firebase Auth / LiveKit tokens |
| Server | mesh-control (Express + Socket.IO) | mediasoup WebSocket server |

Mesh avoids SFU bandwidth for multi-camera input, reserving the SFU only for the final program output.

---

## Implementation Progress

### Complete (v1.0.1 + v1.0.2-R)

- [x] QR-based device pairing with HMAC-signed tokens
- [x] Director and Camera role screens in Flutter
- [x] WebRTC peer connection flow (offer/answer/ICE via Socket.IO relay)
- [x] Mesh-control server (Express + Socket.IO) with Firebase auth
- [x] Production lifecycle endpoints (create, pair, set-layout, status)
- [x] SINGLE and SPLIT_SCREEN layout states on director console
- [x] Layout bridge from mesh-control to mediasoup SFU (`sfuProgramAdapter.ts`)
- [x] Firestore persistence for productions and audit logs
- [x] Docker Compose wiring (mesh-control, mediasoup, coturn, nginx)
- [x] Rate limiting and payload validation on mesh-control server
- [x] Mobile route `/mesh-live` registered in canonical Flutter app

### Not Yet Complete

- [ ] Canonical database persistence (in-memory fallback still present)
- [ ] Full Firebase/SSO authorization enforcement
- [ ] SFU compositor/program-output certification (bridge exists, compositor not fully tested)
- [ ] TURN fallback certification
- [ ] Physical-device certification (no real device testing executed)
- [ ] Protected CI pipeline (no automated CI pass)
- [ ] `FINAL_RUN_TO_GREEN_CHECKLIST.md` is blank — 0 of 15 validation steps executed

### Key Files

| File | Purpose |
|---|---|
| `modules/live-streaming/flutter/lib/src/mesh_live/` | All mesh Flutter screens and API client |
| `modules/live-streaming/server/mesh-control/` | Express + Socket.IO mesh-control server |
| `modules/live-streaming/server/mediasoup/` | Mediasoup SFU server |
| `modules/live-streaming/server/mesh-control/src/sfuProgramAdapter.ts` | Bridge from mesh to SFU |
| `modules/live-streaming/contracts/mesh-live/` | TypeScript type contracts |
| `apps/mobile_flutter/lib/app/app.dart` | Route registration (lines 561-563) |
| `apps/mobile_flutter/pubspec.yaml` | Module dependency (line 10-11) |
