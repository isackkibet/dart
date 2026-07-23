# mobile_mesh Codebase Report

Repo: `Yohpal-International-Limited/mobile_mesh` · Firebase project: `yohlab`
Reviewed: 2026-07-23

## 1. What this repository actually is

The repo name ("mobile_mesh") is misleading — it is not a single mobile app, it's the **entire YohPal Live monorepo**: two competing Flutter clients, a Next.js admin console, a Next.js wallet stub, a live-streaming module, and *five separate, overlapping* backend trees (two Functions trees, two video-pipeline reimplementations, three NestJS microservices). The root README describes it as "the clean rebuild baseline for YohPal Live v2," but the repo also still contains the thing it was meant to replace, side by side, undeleted.

High-level inventory:

| Area | Path | Status |
|---|---|---|
| Canonical mobile app | `apps/mobile_flutter` | **Live** — Firebase-wired, CI release-gated |
| Legacy mobile app | `apps/yohpal_live` | **Dead** — never calls `Firebase.initializeApp()` |
| Admin console | `apps/admin_web` | **Live** — full Next.js app, ~30 API routes |
| Wallet web | `apps/wallet_web` | **Stub** — placeholder pages, not wired to Firebase |
| Streaming module | `modules/live-streaming` | **Partially live** — mesh feature wired in; mediasoup "canonical runtime" is not |
| Deployed functions | `backend/firebase_functions` | **Live** — 35 exported Cloud Functions, referenced by `firebase.json` |
| Abandoned functions | `functions/` | **Dead** — scaffolding only, 1 exported function, not referenced anywhere |
| Deployed video pipeline | `backend/cloud_run_workers` (Python) | **Live** — matches `docs/MEDIA_PIPELINE.md` |
| Orphaned video pipeline | `backend/video-pipeline` (NestJS) | **Dead** — undocumented, no CI, reimplements the above |
| Orphaned microservices | `services/video-delivery`, `services/video-intelligence`, `services/release-control` | **Dead** — undocumented, no CI, overlap each other and `video-pipeline` |
| Superseded patch | `patches/admin-web-complete-gap-fix` | **Dead** — earlier draft, fully subsumed by `apps/admin_web` |

---

## 2. Systems it connects to, and how

**Firebase project `yohlab`** is the hub everything hangs off:
- **Auth**: Firebase Auth (Google/Apple sign-in in `mobile_flutter`; session-cookie based in `admin_web` via `lib/auth.ts`, verified server-side with `auth.verifySessionCookie` against a Firestore `admins/{uid}` RBAC doc).
- **Firestore**: shared database across mobile app, admin console, and Cloud Functions — `videos`, `multistreamSessions`, `meshLiveProductions`, `admins`, plus ~15 domain collections seeded under `firestore/seeds/`.
- **Cloud Storage**: video ingest (`videos-raw/{uid}/...`) → triggers `backend/firebase_functions`'s `onVideoCreated`.
- **Cloud Functions** (`backend/firebase_functions`, deployed per `firebase.json`): the only backend surface the mobile app and admin console actually call. 35 functions across `video/`, `ads/`, `revenue/`, `live/`, `ai/`, `social/`, `search/`, `ycios/`, `context/`, `performance/`.
- **Cloud Run** (`backend/cloud_run_workers`, Python): video transcoding, AI video jobs, multistream RTMP forwarding, search indexing — invoked downstream of the Functions pipeline, not directly by clients.
- **modules/live-streaming**: a self-hosted Node stack (mesh-control + mediasoup SFU + coturn TURN + nginx TLS, via `docker-compose.yml`) that the mobile app talks to over Socket.IO/WebSocket, independent of the Firebase Functions layer except for `firebase-admin` auth verification and Firestore persistence of `meshLiveProductions`.
- **M-Pesa**: `apps/admin_web/lib/mpesaB2C.ts` + `app/api/mpesa/b2c/{result,timeout}` — payout webhook integration, admin-side only.
- **wallet.yohpal.com**: `apps/mobile_flutter` opens this domain via external browser (`url_launcher`) for `/dashboard`, `/withdraw`, `/pay`, expecting a `yohpal://wallet-status?...` deep-link callback. This is a **real, wired mobile-side contract with no corresponding implementation** — `apps/wallet_web` (presumably meant to serve that domain) is still a placeholder.

---

## 3. Integration points in detail

### 3.1 `modules/live-streaming` ↔ `apps/mobile_flutter`
- Package `yohpal_live_streaming` is a Flutter path-dependency (`pubspec.yaml`), imported once via its barrel file (`app.dart`).
- Only the **mesh** feature is actually routed: `/mesh-live`, `/mesh-live/create`, `/mesh-live/join-camera` (`app.dart:561-563`) → `HomePage`, `DirectorSetupPage`, `CameraJoinPage`.
- The module's mediasoup-facing screens (`GoLiveScreen`, `LiveViewerScreen` — the ADR-024 "canonical runtime" UI) are exported by the package but **never routed**. The app instead has its own independent `livekit_client`-based screens at `features/live_streaming/screens/{go_live_screen,live_viewer_screen}.dart`, registered under the *same* route names (`/go-live`, `/live-viewer`).
- Server side: mesh-control (Express/Socket.IO, port 8080) bridges to the mediasoup SFU via `sfuProgramAdapter.ts` (`SFU_CONTROL_URL`/`SFU_CONTROL_TOKEN`), backed by coturn (TURN) and nginx (TLS) — all wired in `modules/live-streaming/docker/docker-compose.yml`.
- Firestore: mesh-control writes `meshLiveProductions/{id}` + an `audit` subcollection, using rules from `modules/live-streaming/firestore/chat_rules.rules` — **which is not merged into the deployed `firestore/firestore.rules`**, so this collection currently has no rules coverage in production.
- Native Android/iOS integration (`modules/live-streaming/android`, `/ios`) is manifest/merge-guide documentation, not compiled code — confirmed **not yet applied** to `apps/mobile_flutter/android|ios`.

### 3.2 `apps/admin_web` ↔ Firebase / M-Pesa
- `middleware.ts` gates ~17 route prefixes behind a session cookie; `lib/auth.ts` enforces a 10-role RBAC matrix read from `admins/{uid}`.
- `lib/repositories/*.ts` (30 files) is the entire Firestore data-access layer — moderation, finance, wallets, live reports, ads, affiliates, polls, discovery, chat, growth, video.
- `app/api/admin/**/route.ts` (~30 endpoints) perform admin actions (approve/reject/ban/etc.) server-side via `firebase-admin`.
- M-Pesa B2C payout webhooks land at `app/api/mpesa/b2c/{result,timeout}`.
- **Not documented anywhere**: neither `docs/FIREBASE_PROJECT_WIRING_CHECKLIST.md` nor `docs/ENVIRONMENT_VARIABLE_MATRIX.md` mentions `admin_web` or `wallet_web`, despite `admin_web` being a fully functional, production-shaped integration.

### 3.3 `apps/wallet_web` ↔ `apps/mobile_flutter`
- Mobile side (`core/web_handoff/yohpal_web_handoff.dart`, `yohpal_environment.dart`) is fully built: opens `https://wallet.yohpal.com/{dashboard,withdraw,pay}` and expects a `yohpal://wallet-status` deep-link callback (handled by `WalletStatusScreen`/`YohPalDeepLinkService`).
- Web side (`apps/wallet_web`) has no matching routes, no Firebase calls anywhere in `app/`, and is functionally a placeholder ("Production starter dashboard").
- `apps/mobile_flutter/lib/features/wallet_web/services/WalletLauncherService.execute()` is also an empty stub.
- **This is the single clearest "required implementation" gap in the whole repo**: the mobile app is ready to hand off to a web wallet that doesn't exist yet.

---

## 4. Required changes, by app

**`apps/mobile_flutter` (canonical app — do the real work here)**
1. Register the mediasoup adapter as the production DI-injected `YohPalLiveStreamingRuntime` (ADR-024 action #1) — currently unregistered.
2. Remove `livekit_client` dependency and the app's own `go_live_screen.dart`/`live_viewer_screen.dart`; route `/go-live`/`/live-viewer` to the module's `GoLiveScreen`/`LiveViewerScreen` instead (ADR-024 actions #2, #5). Right now both runtimes ship in the same build.
3. Apply `modules/live-streaming`'s Android/iOS manifest merges (`ANDROID_MERGE_GUIDE.md`, `IOS_MERGE_GUIDE.md`) — not yet applied.
4. Implement `WalletLauncherService.execute()` for real, once `wallet_web` exists.
5. Map live analytics/recording to the canonical mediasoup session ID (ADR-024 action #3/#4) — not yet done.

**`modules/live-streaming`**
1. Merge `firestore/chat_rules.rules` into the deployed `firestore/firestore.rules` — `meshLiveProductions` currently has zero rules coverage in production.
2. Replace the in-memory persistence fallback with Firestore-only (per `MESH_LIVE_DIAGNOSTIC.md`, still present).
3. Enforce full Firebase/SSO auth (currently partial).
4. Certify the SFU compositor, TURN fallback, and get through at least one physical-device test pass — `FINAL_RUN_TO_GREEN_CHECKLIST.md` is referenced repo-wide as a gate but doesn't actually exist / is unfilled (0/15 steps per the diagnostic).
5. Stand up a protected CI pipeline for this module — none exists today.

**`apps/wallet_web`**
1. Build the actual dashboard/withdraw/pay flows and wire them to Firebase — currently a shell with a `firebase` dependency it never imports.
2. Implement the `yohpal://wallet-status?status=...&reference=...` callback contract the mobile app already expects.
3. Add it to `docs/FIREBASE_PROJECT_WIRING_CHECKLIST.md` / `ENVIRONMENT_VARIABLE_MATRIX.md` once real.

**`apps/admin_web`**
- Functionally the most complete piece of the repo; no urgent integration gaps found. Documentation debt only (not in the wiring checklist).

**Firestore config**
- `firestore/indexes/firestore.indexes.json` (orphaned, 81 `collectionGroup` entries) has far more indexes than the deployed `firestore/firestore.indexes.json` (7 entries). This is worth a manual check — it may represent indexes that are actually needed in production but were dropped, not just staleness.

---

## 5. Duplicated / dead code — recommend deleting

| Duplicate | Verdict | Evidence |
|---|---|---|
| `apps/yohpal_live` (entire app) | **Delete.** Superseded fork of `apps/mobile_flutter`. | Never calls `Firebase.initializeApp()`, no `firebase_options.dart`, build `1.0.0+1` vs mobile_flutter's `1.0.0+7`, 196 dart files/14.2k LOC vs 413 files/32.1k LOC. `platform/{identity,wallet,notifications,search,brain,analytics,deep_links,mission_control,migration,os,routing}` exist near-verbatim but less complete in `mobile_flutter`. Only covered by the lightweight `ci.yml` smoke job; the real release gate (`yohpal_live_ga_gate.yml`) targets `mobile_flutter` exclusively. |
| `functions/` (Firebase Functions tree) | **Delete.** Abandoned parallel rewrite. | `firebase.json` → `functions.source = "backend/firebase_functions"`; CI's `functions` job runs in `backend/firebase_functions`. `functions/src/index.ts` exports one `api` handler; its `src/modules/*` domain scaffolding (ads, autonomy, chat, clipFactory, commandCenter, creatorGrowth, etc.) was never wired in. |
| `backend/video-pipeline` (NestJS) | **Delete**, or explicitly archive as a spike. | Reimplements `backend/cloud_run_workers` (transcode/HLS) *and* both `services/video-delivery` and `services/video-intelligence` (feed ranking, CDN delivery, preload) inside one monolith. Not mentioned in `docs/MEDIA_PIPELINE.md`, no CI job. |
| `services/video-delivery`, `services/video-intelligence`, `services/release-control` | **Delete**, or explicitly archive. | Undocumented, CI-absent, and overlap both each other and `backend/video-pipeline` — looks like an abandoned "extract to microservices" effort that was itself re-duplicated. |
| `firestore/rules/firestore.rules` (orphaned copy) | **Delete.** | Deployed copy (`firestore/firestore.rules`) already has documented fixes for duplicate `adCampaigns`/`polls` blocks that this orphaned copy still has. |
| `patches/admin-web-complete-gap-fix` | **Delete.** | Only covers 6 routes vs. `admin_web`'s ~20+; overlapping files (`auth.ts`, `moderationRepository.ts`) are strictly older/thinner versions. `admin_web`'s own `package.json` version (`2.0.0-admin-gap-fix`) shows the patch was already absorbed. |
| `apps/mobile_flutter`'s LiveKit path (`livekit_client`, `go_live_screen.dart`, `live_viewer_screen.dart`) | **Delete once mediasoup parity is confirmed** (ADR-024 already mandates this). | Duplicates the module's canonical `GoLiveScreen`/`LiveViewerScreen` under identical route names; both ship in the same build today. |

**Not duplicates (confirmed distinct, keep both):**
- `modules/live-streaming/server/{mesh-control,mediasoup}` vs `backend/cloud_run_workers/multistream_worker` — different jobs (live ingest/SFU routing vs. outbound RTMP forwarding to external platforms).
- `apps/yohpal_live/lib/features/{live_streaming,multistream_v2}` — has no dependency on `yohpal_live_streaming`, `livekit_client`, or mediasoup; it's a third, fully separate `flutter_webrtc` implementation. Moot if `apps/yohpal_live` is deleted per above.

---

## 6. Framing for "this as a module inside yohpal live app"

If `modules/live-streaming` is meant to be consumed as a module by a single canonical "YohPal Live" app, that app is `apps/mobile_flutter` — confirmed by CI (`yohpal_live_ga_gate.yml`), by ADR-024 naming it explicitly, and by it being the only app with a working Firebase bootstrap. Today the integration is half-done: the mesh (multi-camera director) feature is live and routed; the mediasoup "canonical runtime" the module was actually built to provide is exported but unused, shadowed by a parallel LiveKit implementation the architecture decision record says should already be gone. Closing that gap (§4, `apps/mobile_flutter` items 1–2) is the highest-leverage single change available in this repo — it's the one place where a documented decision (ADR-024) exists but was never executed.
