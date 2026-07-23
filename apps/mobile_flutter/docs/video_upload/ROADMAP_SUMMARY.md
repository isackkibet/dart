# Creator Studio Video Upload Roadmap — Summary

This folder holds 12 internal planning/spec PDFs for YohPal Live's "Creator Studio" video
creation suite. Eleven are forward-looking release specs (versioned 1.1A through 1.3A); one
("Current Codebase Assessment") is a point-in-time audit of what actually exists in the
codebase. Read together, the specs form a chain: nearly every document closes by naming the
next release as its own recommended follow-up, so the release order below is not just a
numbering scheme — it's the literal sequence the authors intended.

This summary is faithful to each document's stated content. Where a document doesn't define a
section (e.g. no formal acceptance criteria), that's noted rather than invented.

## Roadmap at a glance

| Release | Document | Purpose | Depends on |
|---|---|---|---|
| 1.1A | Video Creation Foundation | Product-vision memo: Creator Studio as an AI-first "Creator OS" | — (originating doc) |
| 1.1A | Disruptive Video Creation Foundation (full spec) | Complete build spec for the 1.1A foundation | Video Creation Foundation |
| 1.1A-RC1 | Core Camera, Timeline & Draft Pilot | Implementation pack for the first release candidate | 1.1A |
| 1.1A-RC1 | Physical Device Validation Report | QA/certification gate for RC1 on real hardware | RC1 Core Pilot |
| 1.1A-RC2 | Privacy Shield — People Image Blurring | Design spec for face/person blurring + voice anonymization | RC1 (must stay gated until RC1 passes) |
| 1.1A-RC2 | Privacy Shield Pilot — Implementation | Build spec + validation plan for Privacy Shield | RC1 foundation, Privacy Shield design |
| 1.1B | AI Production Engine — Master Blueprint | Turns AI *suggestions* into AI *execution* | 1.1A |
| 1.1C | Real-Time AI Co-Creation — Master Blueprint | AI coaches live, during recording, not just after | 1.1B |
| 1.2A | Creator Intelligence Platform (CIP) | Five AI coaching modules (Camera/Speech/Story/Commerce/Twin) | 1.1A timeline/objects model |
| 1.2B | Multimodal Creator Intelligence (MCI) | Unifies vision/speech/language/timeline AI into one orchestrator | 1.1B/1.1C AI services |
| 1.3A | Creator Autonomy Platform (CAP) | Goal-driven strategy: creator picks a goal, AI plans the whole workflow | 1.2A Digital Twin/coaching |
| — | Current Codebase Assessment | Audit of actual implementation state; recommended 1.1A as next step | — (originating audit) |

Note: 1.1C's closing section names its recommended follow-up as "1.2A — Creator Intelligence
Platform," but the document actually produced next in the sequence is 1.2B. It's unclear from
the docs themselves whether a distinct 1.2A-successor was skipped, renamed, or folds into 1.2B.

---

## Current Codebase Assessment

**Purpose:** A diagnostic audit (repository snapshots June–July 2026) separating confirmed
implementation, partial implementation, and unproven claims — used to justify starting the 1.1A
build. Not a spec; no in/out-of-scope section.

**Confirmed working:** Create-hub upload route; gallery video selection (`image_picker`); file
validation (extension + ~250MB size, but no duration/aspect-ratio/resolution/codec/frame-rate/
corrupt-media/audio-track/orientation/quality/copyright/duplicate checks); real (non-simulated)
Firebase Storage upload progress via `UploadTask.snapshotEvents`; Firestore video-document
creation (earlier defects — missing `ownerId`, string dates, wrong `.m3u8` requirement —
reportedly fixed, but the doc says "immutable-commit proof is required"); a public-feed
publication path (governance weak — a video can go public regardless of AI-checklist state).

**Confirmed missing:** No in-app camera recording at all (front/rear switch, pause/resume,
multi-clip, countdown, speed, filters, hands-free) despite UI implying "record or upload"; no
upload reliability layer — no connectivity pre-check, no cancel, no retry, no resumable/
background upload, no queue, no speed/ETA estimate (`connectivity_plus` is a dependency but
unused).

**AI Creator Studio findings:** Job infrastructure (`AiVideoJob`, queued→processing→completed/
failed, audit events, 50/day rate limit) is implemented. Captions, hashtags, and viral score are
implemented — but viral score is advisory only, not calibrated on real performance data (should
be marketed as "content-readiness guidance," not "prediction"). AI hooks and thumbnail ideas are
suggestion-only — no automatic replacement of the opening frame, no rendered thumbnail image,
text overlay, or CTR testing. AI translation exists in the backend but isn't confirmed wired
into the live UI. **AI trim suggestions are advice only** — no evidence the app actually moves
timeline handles, executes a trim, or re-renders. **The five-item AI publication checklist does
not block publication** — `aiPublishStatus` is written but not enforced by the pipeline.

**Critical open question:** Conflicting evidence on HLS/adaptive-bitrate transcoding — one
report claims a working Storage-triggered pipeline; an earlier audit found the Cloud Run
transcoder only ever returned "queued," with raw MP4s temporarily written into the `hlsUrl`
field. Classified **"UNVERIFIED, not certified."**

**Capability matrix:** Native timeline trim/split/merge/crop/rotate/speed, filters/LUTs, beauty,
background removal, music library/beat sync, voice-over, text overlays, stickers, transitions,
duet/stitch, green screen, and templates are all listed **Missing**. Draft persistence and
pre-release moderation are "not sufficiently proven."

**Recommendations (framed as launch priorities, not a formal plan):** One-Tap Smart Edit, Real
Native Timeline Editor, YohPal Camera (with an "AI Director Mode" concept), Automatic Spoken
Captions, Smart Music/Beat Editing, Ecosystem-Native Video Objects (Jobs/Hustle/Market/Course/
Poll on the timeline), Remix/Duet/Stitch, AI Compliance/Safety Assistant. Defines a canonical
`VideoEditProject`/`VideoClipEdit`/`VideoPublicationGate`/`ResumableVideoUploadService` contract
that the 1.1A spec and RC1/RC2 build directly on. Closing line explicitly names **"Build YOHPAL
LIVE CREATOR STUDIO RELEASE 1.1A"** as the next move — this is the document 1.1A was built from.

---

## Release 1.1A — Video Creation Foundation (product-vision memo)

**Purpose:** Argues Creator Studio should become an all-in-one AI-first "Creator Operating
System" (record → edit → AI → commerce → publish → monetize), not another CapCut clone. Stated
objective: "Build the smartest creator platform in Africa."

**Scope:** In scope — the entire Creator Studio surface: Camera, Timeline, Audio, Caption, AI,
Commerce, Publishing, Analytics, Project Manager. No explicit out-of-scope section.

**Key features:** Professional camera (multi-cam, timers, slow/fast/lapse, up to 4K); full
non-linear timeline (trim/split/merge/reorder/undo-redo, per-clip speed/crop/rotate); Audio
Studio (music library, noise/echo reduction, ducking, beat sync, AI music recommendation);
Caption Studio (auto subtitles, AI Subtitle Designer); AI Studio (hooks/hashtags/captions/
thumbnails/viral score today, growing toward AI rewrite/cleanup/thumbnail/analytics/Digital
Twin); Commerce Objects (timestamped interactive Jobs/Market/Wallet/Course/Poll objects);
Publishing Studio (enforced checklist/gates); Project Manager (drafts, autosave, version
history, cloud sync); Creator Analytics.

**Implementation plan:** Ten lettered phases: A) YohPal Camera, B) Timeline Editor, C) Audio
Studio, D) Caption Studio, E) AI Studio, F) Commerce Objects, G) Publishing Studio, H) Project
Manager, I) Creator Analytics, J) AI Production Pipeline (Upload → AI Analysis → Timeline
Changes → Subtitle Gen → Thumbnail → Rendering → Moderation → Publish).

**Deliverables:** A readiness table giving current% → target% per module post-1.1A (e.g. Camera
20%→95%, Timeline 5%→90%, AI 65%→95%, Commerce Objects 5%→95%, Publishing 60%→98%). No formal
acceptance checklist beyond this table.

**Dependencies:** None — the originating vision doc. Recommends 1.1B (AI Production Engine) next.

---

## Release 1.1A — Disruptive Video Creation Foundation (full implementation spec)

**Purpose:** The complete, near-implementation-ready build spec for the 1.1A vision above:
multi-clip camera recording, timeline editing, music/voice-over, captions, drafts/autosave,
resumable uploads, publication gating, and hooks into the existing AI recommendation services.

**Scope:** In scope — camera capture, clip trim/split/delete/reorder, audio tracks, caption
segments, timestamped ecosystem objects, persistent Hive-based drafts, Firebase Storage
resumable uploads, an enforced Publication Gate, FFmpeg rendering. Explicitly deferred: true
process-death upload resumability (pushed to "a later controlled phase" via WorkManager/iOS
background URL sessions); immediate public activation of every feature (advanced features stay
flagged off until validated).

**Key features/requirements:** Full Flutter file/folder structure, exact `pubspec.yaml`
dependencies, a `CreatorStudioFlags` feature-flag class, domain models (`CreatorProject`,
`VideoClipEdit`, `AudioTrackEdit`, `CaptionSegment`, `TimelineObject`, `BrainRecommendations`), a
`PublicationGate`/`VideoPublicationGate` blocking publish until rendering, upload, moderation,
copyright, metadata, caption review, and timeline-object validity all pass; Hive-based project
persistence; camera service/controller; an `FfmpegCommandBuilder` for concat/trim/audio-mix
render plans; caption-generation and YohPal Brain recommendation HTTP services; a resumable
upload repository/coordinator; controllers (project, camera, editor with undo/redo, publish) and
screens (camera, timeline strip, clip tile, caption overlay, publication-gate panel, upload
progress card). Backend: Firebase Functions for upload-session creation, upload finalization,
publish, trusted-object resolution, and the publication gate; Firestore/Storage security rules;
unit tests.

**Step-by-step plan:** A "Phased Launch Activation" (§34) with per-phase flags:
1. **Launch Foundation** — projects, gallery import, camera, multi-clip, trim/split/delete/
   reorder, draft autosave, upload progress/cancel/retry, publication gates (captions/music/
   objects flagged off).
2. **Caption and Audio Pilot** — synced captions, caption editing/translation, music, voice-over,
   audio mixing.
3. **Ecosystem Objects** — Jobs, Hustles, Market products, Courses, Business profiles, Wallet
   offers, AI Ask.
4. **AI Production Integration** — AI captions/hooks/hashtags/thumbnail concepts/viral score/
   trim recommendations, AI-assisted edit application.
5. **Controlled Public Rollout** — gated on device validation, rendering stability, upload
   recovery, moderation/copyright evidence, deep-link tests, wallet/commerce security review,
   Crashlytics evidence, Release Review Board approval.

Also specifies a validation shell script (`validate_creator_studio_1_1a.sh`) running
`flutter analyze`/`flutter test`, backend `npm run lint/build/test`, and git-evidence capture.

**Deliverables:** §35 "Release Acceptance Criteria" — ~18 pass/fail gates (camera, multi-clip,
trim/split, reorder/delete, draft autosave, undo/redo, rendering, music/voice-over, synced
captions, resumable upload, cancel/retry, publication gate, trusted timeline objects, Brain
integration, Android/iPhone device tests, Flutter analyze/tests, backend build, Firestore/
Storage rules, Crashlytics). "Next Smart Move" scopes a 12-item RC1 build with a required
evidence list.

**Dependencies:** Self-contained foundation; everything else in the roadmap builds on it.

---

## Release 1.1A-RC1 — Core Camera, Timeline & Draft Pilot

**Purpose:** Implementation pack for the first release candidate — camera recording, multi-clip
timeline editing, drafts, local rendering, upload — gated behind feature flags.

**Scope:** In scope — camera recording, multi-clip recording, gallery import, trim/split/delete/
reorder, undo/redo, draft autosave/recovery, local FFmpeg rendering, upload with progress/
cancel/retry, mandatory publication gates. Explicitly out of scope/disabled: AI edit execution,
automatic captions, music, voice-over, and the Jobs/Hustle/Market/Course ecosystem objects —
enforced by flags that error if enabled together improperly.

**Key features:** `CreatorStudioFlags` with a `validateRc1()` guard requiring core features
bundled and advanced features disabled; bootstrap wiring for Hive/Firebase; a gallery-import
service (file/size/duration validation, 500MB limit); `CreatorStudioSessionController`
coordinating editing, autosave (600ms debounce), rendering, recovery; `CreatorDraftController`;
Home/Editor/Upload screens; a Crashlytics/Analytics service with a fixed mandatory-event list;
an RC1 route gate; and a **mandatory server-side publication gate** (`publishCreatorVideoRc1` +
`evaluateRc1PublicationGate`) blocking publish unless rendering, upload, moderation, copyright,
title/caption, and caption review are all complete — and blocking it entirely if any uncertified
advanced feature is enabled.

**Step-by-step plan:** An 18-section build sequence — (1) feature flags, (2) app bootstrap, (3)
gallery import, (4) editor session controller, (5) draft recovery, (6) home screen, (7) editor
screen, (8) upload controller, (9) upload/publication screen, (10) Crashlytics, (11) route gate,
(12) mandatory publication enforcement (backend), (13) backend publish function, (14) Flutter
tests, (15) backend tests, (16) CI workflow, (17) an immutable candidate-freeze script, (18) a
validation/evidence script producing 14 mandatory evidence categories — plus (19) a physical-
device validation matrix and (20) explicit GO/CONDITIONAL GO/NO-GO rules.

**Deliverables:** GO requires camera proof on Android + iPhone, multi-clip recording, gallery
import, timeline ops, draft recovery after force-close, synced rendered output, upload cancel/
retry, server-enforced publication blocking of incomplete media, advanced features disabled, zero
unresolved Critical/P0 defects, visible Crashlytics. NO-GO is mandatory on camera failure, clip
loss, corrupt/desynced rendering, uncancellable/unretryable uploads, publishable unprocessed
content, or accessible uncertified features. Stated position: implementation authorized, pilot
activation only after a validated QA build, public rollout not authorized until device evidence
passes.

**Dependencies:** The foundation RC2 explicitly builds on top of.

---

## Release 1.1A-RC1 — Physical Device Validation Report

**Purpose:** The QA/certification gate for RC1 on real Android and iPhone hardware, before any
advanced feature may be turned on.

**Scope:** In scope — Camera → multi-clip timeline → draft recovery → local render → upload →
publication gate, on physical devices only (no simulators). Out of scope/blocked: all "advanced"
features (synced captions, music editing, voice-over, ecosystem objects, AI edit execution) must
stay disabled — release-gated, not delivered here.

**Key requirements:** Immutable candidate verification (matching commit SHA/tag/branch across
Android+iOS builds, clean working tree); mandatory device records (model, OS version, RAM, build
number); a ~25-gate Validation Gate Register (camera, multi-clip, gallery import, trim/split/
delete/reorder, undo/redo, draft autosave, force-close recovery, local render, A/V sync, upload
progress/cancel/retry, server-side publication blocking, feature-flag lock, Crashlytics,
Flutter/backend build+test).

**Step-by-step plan:** Numbered test suites with explicit steps/pass-criteria per gate area
(§4–16); a 17-subfolder evidence directory; a JSON evidence-manifest schema; a defect register
with severity rules; a bash evidence-validation script
(`validate_creator_studio_rc1_evidence.sh`).

**Deliverables:** Formal GO / CONDITIONAL GO / NO-GO rules (§21) — e.g. GO requires all gates
pass and zero P0/Critical defects; CONDITIONAL GO only under narrow conditions with a named
owner/deadline. **Stated current decision: NO-GO — physical-device evidence pending** (all gates
"Not submitted" at time of writing).

**Dependencies:** Validates 1.1A specifically; explicitly blocks starting 1.1B or enabling any
1.1A advanced feature until a binding decision is recorded.

---

## Release 1.1A-RC2 — Privacy Shield — People Image Blurring & Voice Anonymization (design spec)

**Purpose:** A "YohPal Privacy Shield" — Visual Identity Shield (face/person blurring) + Voice
Identity Shield (voice anonymization) — for privacy, child-protection, and journalism/
safeguarding use cases, to ship before the advanced editing suite goes live.

**Scope:** In scope — person detection+tracking (not just face detection), protection styles
(blur/pixelate/silhouette/mosaic/masks), Privacy Mode vs. Creative Mode as distinct intents,
human-confirmed (not auto-declared) minor-protection workflow, consent-aware workflow, voice
diarization/transformation with privacy vs. creative presets, pre-publication leak checks
(visual/audio/metadata), timeline integration via new protection-track types, storage/security
isolation of original vs. protected media, a server-side privacy publication gate. Explicit
caveat: the system must never claim it can reliably determine exact age or guarantee absolute
anonymity.

**Key requirements:** Visual shield combines face detection + face tracking + person detection +
body tracking + temporal identity association + manual correction. Voice shield combines pitch +
formant + spectral + timing + noise-floor + source-track removal (pitch-shift alone is deemed
insufficient). Detailed Dart domain code (`VisualProtectionTrack`, `VoiceProtectionTrack`,
`PrivacyShieldState`, `PrivacyShieldController`) plus TS server contracts for rendering and a
publication gate blocking publish until scanning/review/protected-render/low-confidence-
resolution/original-exclusion all pass.

**Step-by-step plan:** A 4-phase release strategy — Phase 1 Controlled Visual Shield → Phase 2
Controlled Voice Shield → Phase 3 Multi-Person Intelligence → Phase 4 High-Risk Certification
(enabled only after an independent security/privacy review).

**Deliverables:** §24 "Required Validation" lists test scenarios (stationary/moving faces,
multiple people, side profile, reflections, overlapping speakers, etc.) and a privacy-leak
review — no formal GO/NO-GO table like RC1's; this reads as a design/build spec rather than a
certification report.

**Dependencies:** Positioned to be built/validated before captions/music/voice-over/ecosystem
objects/AI edit execution are enabled — parallel gate to the RC1 Core Pilot.

---

## Release 1.1A-RC2 — Privacy Shield Pilot — Implementation Codebase

**Purpose:** The build spec turning the Privacy Shield design above into a working RC2 pilot on
top of the RC1 foundation, without activating captions/music/voice-over/ecosystem objects/AI
edit execution.

**Scope:** Same feature set as the design doc, now as a monorepo build spec: person/face
detection with stable track IDs, selectable visual protection styles with manual mask
correction, speaker/voice detection with anonymization presets (witness maximum, child
protection, creative, standard/anonymous interview), protected rendering, strict original-vs-
protected media separation, server-enforced privacy publication gates, allow-list/emergency-
disable controls. Release constraint: RC2 stays allow-listed until physical Android/iPhone tests
prove no unprotected person appears, no original voice leaks, the public video document
references only protected output, and the original source cannot be published directly.

**Key features:** New module structure across Flutter (domain/data/services/controllers/
presentation), Firebase Functions (privacy-shield module), and a Cloud Run `privacy-renderer`
worker (FFmpeg-based mask/voice compositing) plus Firestore/Storage rules. RC2-specific flags
(`privacyShieldEnabled`, `visualShieldEnabled`, `voiceShieldEnabled`,
`manualMaskCorrectionEnabled`, `witnessMaximumEnabled`, `creativeVoiceEnabled`, allow-list and
publication-gate-required flags) with a `validateRc2()` guard. Domain models (`PrivacyMode`,
`VisualProtectionTrack`/`VoiceProtectionTrack` with `readyToRender`/`readyForPublication` logic
requiring scan+review+low-confidence-resolution+protected-render+blocked-original), a
`PrivacyShieldController` orchestrating scan→review→render, a manual mask-correction UI
(draggable rect editor). Backend: allow-list enforcement (`createPrivacyScan` checks
`creatorPrivacyAllowList`), protected render creation with server-side validation that every
enabled track is reviewed (and, for protected-witness mode, has zero original voice mix), an
`evaluatePrivacyPublicationGate` function, and `publishProtectedVideo` which deliberately writes
`sourceAssetId: null` to the public video document. Storage/Firestore rules restrict mask/
transformed-audio/protected-output writes to trusted backend workers and keep the original
source never publicly readable.

**Step-by-step plan:** 20 numbered sections — (1) monorepo changes, (2) flags/allow-list, (3)
domain models, (4) detection contracts, (5) Privacy Shield controller, (6) manual mask
correction, (7) protected-rendering contract, (8) backend contracts, (9) allow-list enforcement,
(10) protected render creation, (11) privacy publication gate, (12) protected publication
function, (13) storage isolation, (14) Firestore rules, (15) rendering-worker interface, (16)
voice-anonymization safety rules (zero original voice asserted for high-risk modes; creative
presets explicitly labeled "not certified for high-risk anonymity"), (17) Privacy Shield entry
screen, (18) automated tests (gate tests + Flutter readiness test), (19) a mandatory physical-
device test matrix (visual/voice/publication bypass-attempt tests), (20) a 15-directory evidence
package and a 20-item developer/QA checklist.

**Deliverables:** GO requires visual protection to pass all mandatory Android/iPhone cases, no
reviewed person visible unprotected, zero original voice in Witness Maximum published output,
working manual correction, only protected output public, original media stays private, server
gates reject all bypass attempts, zero open Critical/P0 privacy defect. CONDITIONAL GO only for a
restricted allow-listed pilot with a named owner/deadline. NO-GO mandatory if any protected
person appears unblurred, a mask is lost after movement/re-entry, original voice is audible,
original source is publishable/downloadable, or evidence doesn't match the immutable RC2 tag.

**Dependencies:** Explicitly extends "the immutable RC1 camera-to-render-to-upload foundation"
without activating RC1's still-disabled advanced features.

---

## Release 1.1B — AI Production Engine — Master Blueprint

**Purpose:** Evolve YohPal from a video-upload app into "an AI production company inside every
creator's phone" — connect existing AI *suggestions* to actual execution (rendering, editing,
publishing).

**Scope:** In scope — the full AI Production Pipeline: Idea → AI Director → Recording →
Timeline → AI Analysis → AI Rendering → AI Publishing → Moderation → Distribution → Analytics →
Continuous AI Learning. No explicit out-of-scope section; each phase notes "Current" (mostly
suggestion-only) vs. "Need" (execution).

**Key features/phases (12 numbered):** 1) AI Director (asks creator objective, generates
storyboard/camera instructions/voice script/teleprompter/overlay suggestions); 2) AI Analysis
Engine (detects silence, poor lighting, shaky camera, weak hook/ending, low energy, noise); 3) AI
Auto Editor (actually trims/splits/merges/removes silence, with creator approval step); 4) AI
Subtitle Engine (real generation, multiple styles, burn-in/SRT/VTT/ASS); 5) AI Thumbnail Engine
(10 thumbnails + CTR prediction); 6) AI Audio Engine (noise reduction, music sync, voice cloning/
voice-over); 7) AI Object Engine (interactive Jobs/Market/Wallet/Course/Affiliate/Donation/
AI-Ask objects at timestamps); 8) AI Publishing Engine (checks compliance, auto-fixes or
explains); 9) Creator Digital Twin ("edit like my previous viral videos"); 10) AI Analytics
(hook/thumbnail/caption/object/music performance dashboard); 11) AI Render Engine; 12) AI
Continuous Learning (YohPal Brain learns from every published video).

**Deliverables:** A readiness table (current% → target% per module, e.g. AI Director 20%→95%,
AI Rendering 10%→90%, AI Objects 5%→98%, AI Publishing 60%→99%) and required Dart codebase
contracts (`AiProductionJob`, `TimelineExport`, etc.). No formal GO/NO-GO gate like RC1.

**Dependencies:** Builds directly on 1.1A's foundation and existing AI suggestion services.
Recommends 1.1C next.

---

## Release 1.1C — Real-Time AI Co-Creation — Master Blueprint

**Purpose:** Shifts YohPal Brain from a post-production assistant to a live creative partner
that coaches/directs/edits *while* the creator records.

**Scope:** In scope — real-time coaching across camera, speech, story, scene, captions,
commerce, publishing, plus the Creator Digital Twin and multi-device collaboration. No explicit
out-of-scope section.

**Key features (12 modules):** 1) AI Camera Coach (live framing/lighting/eye-contact checks with
verbal coaching); 2) AI Speech Coach (pace/clarity/filler-word/energy feedback); 3) AI Story
Coach (predicts retention, suggests structural changes); 4) AI Scene Director (suggests next
shot); 5) Live Caption Engine (captions generated during recording; English/Swahili/French/
Arabic at launch, more African languages later); 6) Live Object Suggestions; 7) Live Commerce
Assistant; 8) Creator Digital Twin (learns and eventually auto-applies personal style); 9) AI
Production Score (live dashboard scoring recording/editing/lighting/hook/speech/commerce/
readiness); 10) Live AI Chat (in-editor natural-language commands: "improve this," "shorten,"
"translate"); 11) Real-Time Collaboration (future: multi-creator sessions coordinated by Brain);
12) AI Render Engine (auto-applies captions/music/objects/thumbnail at render time).

**Step-by-step plan:** An explicit 4-sprint roadmap — Sprint 1: Camera Coach, Speech Coach, Live
Caption Engine, real-time feedback overlay. Sprint 2: Story Coach, Scene Director, commerce
recommendations, interactive timeline objects. Sprint 3: Creator Digital Twin, personalized
coaching, live AI chat, AI production scoring. Sprint 4: multi-device collaboration, advanced
learning models, continuous optimization.

**Deliverables:** A competitive-positioning table (vs. TikTok/Reels/Shorts/CapCut) claiming
YohPal targets real-time AI camera coaching, Creator Digital Twin, and ecosystem objects where
competitors don't. Stated engineering principles: AI suggestions assistive not automatic by
default, reversible edits, on-device preference for responsiveness/privacy, graceful degradation
on low-end devices. No formal acceptance test/GO-NO-GO section.

**Dependencies:** Built directly on 1.1B (reuses AI Director, existing suggestion services).
Names 1.2A as its recommended next release — though the next document actually produced is
1.2B (see roadmap-table note above).

---

## Release 1.2A — Creator Intelligence Platform (CIP)

**Purpose:** Layers AI coaching/intelligence onto the 1.1A foundation via "YohPal Brain,"
delivered as independent, reusable services rather than embedded app logic.

**Scope:** No explicit in/out-of-scope statement; architecturally scoped to five AI modules plus
supporting platform capabilities (assistance-level control, privacy, effectiveness measurement).

**Key features:** Camera Coach (framing/lighting/stability scoring), Speech Coach (pace/energy/
clarity/filler-word analysis), Story Coach (retention prediction, hook/flow analysis), Commerce
Coach (suggests product/job/hustle/course/wallet/donation/business objects), Creator Digital
Twin (learns editing/music/caption/thumbnail preferences over time). A 4-level AI Assistance
model (Manual/Suggestions/Assisted/Auto Production, conservative default, reversible), granular
privacy controls (per-capability on/off, cloud-processing policy, twin reset), an AI
Effectiveness Dashboard tied to business outcomes, and an A/B Experiment Framework.

**Implementation plan:** No phased rollout (unlike 1.1A); instead a "Required Codebase" of Dart
contracts/models (`CreatorAiService` interface, per-module result classes,
`CreatorTwinProfile`, `AiAssistanceLevel` enum, experiment/outcome-metrics classes).

**Deliverables:** A "Release Success Criteria" table with per-area percentage targets (Camera/
Speech/Story/Commerce Coach 95%, Digital Twin 90%, privacy controls/AI settings/experiment
framework 100%, outcome analytics 95%) — no further detail on measurement method.

**Dependencies:** Builds on 1.1A's `CreatorProject`/timeline/objects model. Proposes 1.2B next.

---

## Release 1.2B — Multimodal Creator Intelligence (MCI)

**Purpose:** Transforms YohPal Brain into a unified multimodal intelligence platform —
vision, speech, language, timeline, commerce, and creator history understood together, not in
isolation.

**Scope:** In scope — 10 modules under a "Creator Intelligence Orchestrator" architecture
(Vision AI, Speech AI, Language AI, Timeline AI feeding Creator Twin and Commerce Intelligence,
feeding Publishing Intelligence, feeding the Flutter app). No explicit out-of-scope section, but
privacy/consent boundaries are treated as first-class.

**Key features (Modules 1–10):** Vision Intelligence (face/eye-contact/lighting/composition/
brand-visibility with live suggestions); Speech Intelligence (pace/confidence/clarity/energy/
filler-words/emotion/accent); Language Intelligence (speech-to-text, translation, hook/
readability/sentiment/CTA analysis — English/Kiswahili/French/Arabic at launch, staged expansion
to 9 more African languages); Timeline Intelligence (whole-timeline weaknesses: weak opening/
pacing/repetition, suggests trim/reorder/merge/CTA placement); Commerce Intelligence
(recommendation-only unless creator opts into auto-insertion); Creator Twin Intelligence
(viewable/exportable/resettable learned patterns); Explainable AI (every recommendation must
state a data-backed "why"); Offline AI (defines which coaching works offline vs. needs cloud); AI
Orchestration (parallel dispatch so one slow service doesn't block others); Continuous Evaluation
(every recommendation tied to a measurable outcome).

**Implementation plan:** No sprint/phase breakdown; organized as 10 sequential architectural
modules plus a Privacy Model (per-analysis-type settings, cloud-processing policy, delete AI
history, reset Creator Twin) and a Required Codebase (`MultimodalInput`, `CreatorRecommendation`,
`CreatorIntelligenceService` orchestrator interface, `CreatorAiPreferences`, `AiExperiment`,
`CreatorSuccessMetrics`).

**Deliverables:** A Success Criteria table with per-module targets (Vision/Speech/Language/
Timeline/Commerce/Creator Twin AI: 95%; Explainable AI, Privacy controls, Experiment framework,
Evaluation dashboard: 100%; Offline coaching: 90%). Stated engineering principles: hybrid
on-device/cloud architecture, reviewable/reversible AI edits, well-defined service contracts,
confidence-ranked explained recommendations, resettable personalization.

**Dependencies:** Builds on and unifies 1.1B/1.1C's Vision/Speech/Timeline/Commerce AI services
via the orchestrator. Proposes 1.3A next.

---

## Release 1.3A — Creator Autonomy Platform (CAP)

**Purpose:** Reframes the product around creator *goals* rather than editing — "What do you want
to achieve?" drives strategy, workflow, coaching, publishing, and analytics.

**Scope:** No explicit in/out section; scope defined by the Goal Engine architecture (Goal →
Strategy → Production Plan → Recording → Editing → Publishing → Analytics → Learning → Next
Recommendation).

**Key features:** A Creator Goal Engine with six goal categories (Business Growth, Recruitment,
Education, Creator Growth, Community, Revenue) plus a custom Goal Builder; an AI Strategy Builder
generating full production strategies (timing, angle, hook, music, captions, thumbnail, product
object, publishing time); goal-specific Production Workflow Templates and goal-aware AI
Coaching; an Intelligent Publishing Plan (schedule, cross-post, boost, notify); an Ecosystem
Object Planner; outcome-based Success Measurement (orders, applications, enrolments, revenue,
followers — not just views/likes); reusable Creator Playbooks; a Creator Intelligence Dashboard;
Digital Twin evolution into a "strategic advisor"; continuous A/B experimentation across
playbooks. Seven "Creator Autonomy Principles" govern all AI behavior: creator chooses the goal,
AI recommends only, explanations required, automation optional/reversible, personalization
reviewable/resettable, success is outcome-based.

**Implementation plan:** No phased milestones; a "Required Codebase" (Dart classes:
`CreatorGoal`, `GoalStrategy`, `CreatorPlaybook`, `GoalOutcome`, `StrategyRecommendation`) and a
"Platform Workflow" diagram.

**Deliverables:** No explicit deliverables list or acceptance table (unlike 1.1A and 1.2A) —
success is described only qualitatively via the seven autonomy principles.

**Dependencies:** Builds conceptually on 1.2A's Digital Twin and coaching services. Recommends
CAP become a shared cross-product capability (YohPal Live, Jobs, Market, YCIOS, Business,
Government/NGO) via a new "Goal Orchestrator" service inside YohPal Brain, proposing a further
follow-on release: "YohPal Brain Platform Release A5 — Goal Orchestration Engine."

---

## How this connects to work already done this session

Two things already fixed in this codebase map directly onto gaps this roadmap itself flags:

- The **AI publication checklist not actually blocking publication** (flagged in the Current
  Codebase Assessment, and structurally true of `aiPublishStatus` in
  `lib/features/video_editor_ai/`) is the same gap addressed earlier this session in
  `video_processing_status_screen.dart` — that screen no longer dead-ends the creator on a
  mandatory-looking "Enhance with AI" prompt, since the checklist was never wired into the real
  publish/feed pipeline to begin with.
- The **HLS/transcoding "UNVERIFIED" flag** in the Current Codebase Assessment lines up with the
  concrete bug found and fixed earlier this session in `processVideoUpload.ts` /
  `extractVideoThumbnail.ts`: the thumbnail-extraction step called a bare `ffmpeg` binary that
  doesn't exist in the Cloud Functions runtime, silently failing on every upload. The transcoding
  pipeline itself is real and deployed (confirmed via `firebase functions:list`), but this is a
  concrete example of exactly the kind of "claims real, evidence says otherwise" gap this
  assessment doc is warning about — worth treating the rest of its "UNVERIFIED" claims (native
  camera, upload resumability, native timeline editor, AI trim execution) as still open until
  each is independently checked against the current code, not assumed fixed by any of the later
  release docs having been *written*.
