# Capture → Post: Full Flow Reference — 2026-07-16

End-to-end trace of every step between a creator tapping "record" and their video showing up
live in the feed, with the current status of each step. This supersedes the narrower
`upload_flow_review_2026-07-16.md` (which covered the editor/publish bug) by covering the whole
pipeline, including the legacy transcode/moderation stages downstream of publish.

**Bottom line up front:** the flow is still broken end-to-end because two backend/infra pieces
documented in `BACKEND_CHANGES_REQUIRED.md` (repo root) haven't been deployed yet. The client-side
fix made in this session (writing to the right Firestore doc, uploading to the right Storage path)
is necessary but not sufficient — nothing publishes successfully until the Storage rule and the
`publishCreatorVideo` Cloud Function are updated and deployed. See the status table in §2.

## 1. The full path, stage by stage

```
Capture / Gallery            UploadScreen
   ↓
Local CreatorProject          Hive (on-device only, never synced)
   ↓
Timeline edit (optional)      CreatorEditorScreen + CreatorEditorController
   ↓
Local FFmpeg render           CreatorRenderScreen → FfmpegLocalRenderer
   ↓
Render output validation      RenderOutputValidator
   ↓
Client-side publication gate  CreatorPublicationGate (advisory only)
   ↓
Storage upload                CreatorPublishService.uploadRenderedOutput  ⚠️ needs Storage rule
   ↓
Firestore mirror              CreatorPublishService.mirrorProject → videos/{id}
   ↓
Server publish callable       publishCreatorVideo (Cloud Function)        ❌ still reads wrong collection
   ↓
Pending moderation            videos/{id}.status = 'pending_moderation'
   ↓
Transcode pipeline            processVideoUpload → (external transcoder) → registerHlsVideos
   ↓
Playback finalized            finalizeVideoPlaybackAssets → playbackReady = true
   ↓
Live in feed                  videos/{id}.status = 'live', visible via feed queries
```

### 1a. Capture / gallery import
**File:** `lib/features/video_upload/screens/upload_screen.dart`

Camera preview + record, or gallery pick via `image_picker`. The captured file is copied into
app-documents `raw_videos/` (`_persistLocally`, `DefaultVideoStoragePaths.rawVideoPath` — this is
a **local filesystem path**, unrelated to Firebase Storage, easy to confuse with the Storage
`videos-raw/` prefix used later). Duration is probed (`VideoProbeService`), a `CreatorProject`
with one `VideoClipEdit` is created and saved to Hive, then the editor opens.

Status: ✅ working (unchanged by this session's edits).

### 1b. Local project persistence
**File:** `lib/features/creator_studio/repositories/hive_creator_project_repository.dart`

Every edit (trim/split/delete/reorder/metadata) autosaves (500ms debounce) to a Hive box on
device. Nothing here touches the network — the project doesn't exist server-side at all until
publish.

Status: ✅ working.

### 1c. Timeline editing (optional)
**Files:** `creator_editor_controller.dart`, `creator_editor_screen.dart`

Add/trim/split/delete/reorder clips, undo/redo via `EditorHistory`. "Skip editing" and
"continue to render" currently do the exact same thing (both just proceed to render) — every
project, edited or not, goes through the same render step; see the earlier review doc for a
proposed fast-path for untouched single clips.

Status: ✅ working.

### 1d. Local render
**Files:** `creator_render_screen.dart`, `ffmpeg_command_builder.dart`, `ffmpeg_local_renderer.dart`

Every clip is trimmed and re-encoded (`libx264`/`aac`), then concatenated (`-c copy`) into one
output file in app-documents. `RenderOutputValidator` checks the result before
`controller.markRendered(outputPath, sha256)` stores the local path + checksum on the project.

Status: ✅ working.

### 1e. Client-side publication gate
**File:** `creator_publication_gate.dart`

Advisory-only pre-check (clips non-empty, title present, render output present/validated,
upload completed) before attempting the network calls. Mirrors the server gate's logic but isn't
trusted — see 1h.

Status: ✅ working (as a UI gate; doesn't affect the actual break).

### 1f. Storage upload — ⚠️ blocked without a rule deploy
**File:** `creator_publish_service.dart`, method `uploadRenderedOutput`

As of this session: uploads the rendered `.mp4` to Firebase Storage at
`videos-raw/{userId}/{projectId}.mp4` (previously `videos-rendered/...`, which had zero chance of
working — no rule ever covered it).

**`videos-raw/` has no Storage rule either.** `storage/storage.rules` only defines
`live-sessions/`, `clips/`, `admin/`; everything else is `allow read, write: if false`. So this
call still fails with `permission-denied` today. The required rule is written up in
`BACKEND_CHANGES_REQUIRED.md` §2 but **not yet deployed**.

Status: ❌ broken — this is almost certainly the first failure a creator hits right now.

### 1g. Firestore mirror
**File:** `creator_publish_service.dart`, method `mirrorProject`

Writes/merges lifecycle + validation fields (`renderedSha256`, `uploadObjectPath`, `rawPath`,
`clipCount`, `timelineDurationMs`, `outputValidated`, `title`, `caption`, `tags`, `userId`,
`ownerId`, `status: 'uploaded'`) onto the existing `videos/{project.id}` Firestore document. Fixed
this session — previously this either wrote nothing useful (wrong field shape for a nonexistent
`creatorProjects` doc) or, worse, silently created a broken public `videos/{id}` doc.

This step itself now succeeds under the current Firestore rules (`videos/{videoId}` already
allows `create` for any signed-in user, and `update` once `userId` matches — which this write now
sets correctly). It just can't be *reached* today because step 1f throws first.

Status: ✅ fixed client-side, but unreachable until 1f is unblocked.

### 1h. Server publish callable — ❌ still broken
**File:** `backend/firebase_functions/src/creatorStudio/publishCreatorVideo.ts`

Reads the source-of-truth record from `creatorProjects/{projectId}` — a collection nothing has
ever written to — so this throws `not-found` on every call, independent of anything the client
does. On top of that, its success path creates a **new** `videos/{randomUUID}` document instead of
updating the one the client already wrote in 1g, which would produce a duplicate/orphaned record
even if the lookup were fixed.

The fix (read/update `videos/{projectId}` in place) is written up in `BACKEND_CHANGES_REQUIRED.md`
§1 but **not yet implemented or deployed** — this task was explicitly scoped to client-only
changes plus documentation.

Status: ❌ broken — this is the second failure a creator would hit, right after 1f is fixed.

### 1i. Moderation → transcode pipeline
**Files:** `backend/firebase_functions/src/video/processVideoUpload.ts`,
`registerHlsVideos.ts`, `finalizeVideoPlaybackAssets.ts`

Once a file lands under `videos-raw/{userId}/{videoId}.mp4`, `processVideoUpload` (Storage-object
trigger) locates the matching `videos/{videoId}` doc (by `rawPath`, `originalUrl`, or doc-id
match — the creator-studio doc ID always equals the filename stem, so the id-match fallback would
find it even without the `rawPath` field) and enriches it with a thumbnail and owner username.
Something downstream (external transcoder, not in this repo) is expected to produce HLS output
under `videos-hls/`; `registerHlsVideos` (a manually-invoked admin callable, not automatic) scans
for `master.m3u8` files and sets `hlsUrl`/`hlsManifestUrl`/`videoUrl`. `finalizeVideoPlaybackAssets`
(Firestore-triggered) flips `playbackReady: true` once `processingStatus === 'transcoded'` and all
of thumbnail/preview/hlsLow/hlsStandard URLs are present.

Status: ⚠️ untested against creator-studio output — this part of the pipeline was built for the
legacy raw-upload flow and has never received a creator-studio-rendered file, since nothing has
gotten this far yet. Once 1f/1h are fixed, this is the next thing to verify with a real device
run (worth flagging: `registerHlsVideos` requiring manual invocation, rather than being
triggered automatically, may itself be a gap for a smooth publish experience — confirm whether
something else triggers transcoding automatically, or whether creator-studio videos would get
stuck at `pending_moderation` waiting on a manual step).

### 1j. Live in feed
**Files:** `video_feed_repository.dart`, `video_repository.dart`, `zero_wait_feed_repository.dart`

All feed queries filter `where('status', isEqualTo: 'live')`. A video only appears once the
pipeline above sets `status: 'live'` — nothing in the creator-studio path sets that value
directly; it depends entirely on 1h/1i completing successfully. `VideoProcessingStatusScreen`
polls `videos/{videoId}` and returns the creator to the feed once `status == 'live'`.

Status: unreachable until every prior step works.

## 2. Status summary

| Step | Component | Status |
|---|---|---|
| 1a Capture/import | `upload_screen.dart` | ✅ working |
| 1b Local persistence | `hive_creator_project_repository.dart` | ✅ working |
| 1c Timeline edit | `creator_editor_controller/screen.dart` | ✅ working |
| 1d Local render | `ffmpeg_command_builder/local_renderer.dart` | ✅ working |
| 1e Client gate | `creator_publication_gate.dart` | ✅ working |
| 1f Storage upload | `creator_publish_service.dart` | ❌ **permission-denied — Storage rule not deployed** |
| 1g Firestore mirror | `creator_publish_service.dart` | ✅ fixed, unreachable until 1f works |
| 1h Publish callable | `publishCreatorVideo.ts` | ❌ **not-found — reads wrong collection, not deployed-fixed** |
| 1i Transcode pipeline | `processVideoUpload.ts` et al. | ⚠️ unverified against creator-studio output |
| 1j Live in feed | feed repositories | blocked on all of the above |

## 3. What actually unblocks this

Both remaining blockers are backend/infra, documented in detail in `BACKEND_CHANGES_REQUIRED.md`:

1. Deploy the `videos-raw/{userId}/{fileName}` Storage rule (§2 of that doc) — unblocks 1f.
2. Implement and deploy the `publishCreatorVideo.ts` fix to read/update `videos/{projectId}`
   in place (§1 of that doc) — unblocks 1h.

Until both ship, every publish attempt will fail at 1f with `permission-denied` — that's very
likely what "still broken" refers to right now, and it's the same failure regardless of how many
more client-side tweaks are made, since the client can't route around a security rule.
