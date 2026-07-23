# Backend Changes Required — Creator Studio Publish Flow

This documents the backend/infra work needed to complete the client-side refactor that moved the
creator-studio publish flow off a never-created `creatorProjects` collection and a dead
`videos-rendered/` Storage path, onto the app's real, existing `videos` collection and
`videos-raw/` Storage convention. **Nothing in this file has been implemented** — client changes
only were made in this pass; see `apps/mobile_flutter/docs/video_upload/video_edit/prompt` for the
scoping instruction.

> **Path spelling correction:** the source prompt for this task specifies the Storage prefix as
> `videos_raw` (underscore). The actual existing pipeline —
> `backend/firebase_functions/src/video/processVideoUpload.ts` — only triggers on objects under
> `videos-raw/` (hyphen) or the legacy `videos/raw/` (slash), never `videos_raw` (underscore). The
> prompt's own top-level requirement is to "keep the implementation aligned with the existing
> video processing pipeline," so this doc and the client code both use **`videos-raw`
> (hyphen)** — matching what's actually wired up — rather than the literal underscore spelling.
> Using underscore would silently recreate the exact "dead path" bug this refactor exists to fix:
> the file would upload fine but `processVideoUpload` would never fire, so no thumbnail/transcode
> pipeline would ever start. If underscore was intentional (e.g. a deliberate rename), that would
> also require updating `processVideoUpload.ts`'s trigger condition — flag this back if so.

## 1. Cloud Function changes

**`backend/firebase_functions/src/creatorStudio/publishCreatorVideo.ts`**

Currently reads the source-of-truth project record from `creatorProjects/{projectId}` (a
document nothing ever creates) and, on success, creates a **new** document under a fresh
`randomUUID()` in `videos/{videoId}`.

Required change:

```
before:  creatorProjects/{projectId}  →  videos/{randomVideoId}
after:   videos/{projectId}           →  videos/{projectId}
```

The callable should:

1. Read `videos/{projectId}` (the document `CreatorPublishService.mirrorProject` already wrote
   client-side) instead of `creatorProjects/{projectId}`.
2. Validate using the existing `evaluateServerPublicationGate` (`publicationGate.ts`) — no logic
   change needed there, see below.
3. Update that same document in place instead of creating a new one under a random id:

```ts
// before
const projectRef = db.collection('creatorProjects').doc(input.projectId);
...
const videoId = randomUUID();
const videoRef = db.collection('videos').doc(videoId);
...
transaction.set(videoRef, { ... });

// after
const videoRef = db.collection('videos').doc(input.projectId);
...
transaction.update(videoRef, {
  status: 'pending_moderation',
  publishedAt: FieldValue.serverTimestamp(),
});
```

4. Return:

```json
{ "videoId": "{projectId}", "status": "pending_moderation" }
```

i.e. `{ videoId: input.projectId, status: 'pending_moderation' }` — the client's
`VideoProcessingStatusScreen` already just uses whatever `videoId` the callable returns, so no
client change is needed once this ships.

**`backend/firebase_functions/src/creatorStudio/publicationGate.ts`**

No logic changes needed — it already validates `project.status`, `project.outputValidated`,
`project.renderedSha256`, `project.uploadObjectPath` generically against whatever
`CreatorProjectRecord` it's handed. Those exact field names are what the client's
`mirrorProject` now writes onto `videos/{projectId}`, so this keeps working once
`publishCreatorVideo.ts` points it at the right document.

**`backend/firebase_functions/src/creatorStudio/creatorStudio.types.ts`**

`CreatorProjectRecord` currently models a standalone project record. Since it now describes a
slice of the shared `videos/{id}` document, consider renaming/documenting it as such (e.g. add a
comment noting these fields live alongside the legacy pipeline's fields — `processingStatus`,
`playbackReady`, `hlsLowUrl`, etc. — on the same document). No field renames are required; the
shapes already match what the client writes.

## 2. Firebase Storage rules (`storage/storage.rules`) — required

No rule currently covers the `videos-raw/` prefix that both the legacy upload flow and (as of
this refactor) creator-studio's rendered-output upload use. `storage.rules` today only defines
`live-sessions/`, `clips/`, and `admin/`; everything else falls through to `allow read, write: if
false`. **This is why the storage write fails today**, and it stays broken — `permission-denied`
on every publish attempt — until this rule ships, regardless of any client-side fix.

Add:

```
match /videos-raw/{userId}/{fileName} {
  allow read: if signedIn() && request.auth.uid == userId;
  allow write: if signedIn() && request.auth.uid == userId
    && request.resource.size < 500 * 1024 * 1024
    && request.resource.contentType == 'video/mp4';
}
```

(Adjust the size ceiling to match whatever limit the rest of the upload pipeline already enforces
client-side, if different from 500MB.)

## 3. Firestore rules (`firestore/firestore.rules`)

The existing `videos/{videoId}` rule already technically permits the client's write (`allow
create: if signedIn()`, `allow update: if auth.uid == resource.data.userId` — the client now sets
`userId` correctly on every write, so `mirrorProject` succeeds under the current rules as-is). But
it doesn't yet satisfy the requirements this flow actually needs:

- Users can create their own video documents. ✅ already true (no owner check on `create` today,
  but the client always sets `userId: project.ownerId` to itself — see gap below).
- Users can update only their own **unpublished** documents. ❌ not enforced — today an owner can
  update a doc at any status, including one already in `pending_moderation` or later.
  Cloud Functions write via the Admin SDK, which bypasses security rules entirely, so this gap
  doesn't let a client bypass moderation outcomes — but it does let a client freely rewrite a
  document's content after submission, including fields moderators may rely on.
- Users cannot modify moderation state after submission. ❌ not enforced today — nothing stops a
  client from setting `status` directly to `'pending_moderation'`, `'live'`, `'approved'`, etc.
  (`publishCreatorVideo`'s own transaction check, `latestProject.status !== 'uploaded'`, protects
  the *publish* callable from racing a stale status, but doesn't stop a client from writing those
  status values directly to Firestore outside that callable).
- Cloud Functions remain responsible for `pending_moderation`/approval/rejection/publishing
  transitions. Already true operationally (only `publishCreatorVideo` and the transcode-pipeline
  functions set those values), but not *enforced* by rules — recommend making it structural:

```
function clientWritableStatus(status) {
  return status in ['uploading', 'uploaded', 'failed'];
}

match /videos/{videoId} {
  allow read: if true;
  allow create: if signedIn()
    && request.resource.data.userId == request.auth.uid
    && clientWritableStatus(request.resource.data.status);
  allow update: if signedIn()
    && request.auth.uid == resource.data.userId
    && clientWritableStatus(resource.data.status)
    && clientWritableStatus(request.resource.data.status);
  allow delete: if signedIn() && request.auth.uid == resource.data.userId
    && clientWritableStatus(resource.data.status);
}
```

This confines client writes to the pre-moderation lifecycle (`uploading`/`uploaded`/`failed`);
once a Cloud Function (Admin SDK, bypasses rules) flips `status` to `pending_moderation` or later,
`resource.data.status` no longer satisfies `clientWritableStatus`, so further owner-side
create/update/delete calls are rejected — satisfying both "only unpublished" and "can't modify
moderation state after submission."

**Adjacent, pre-existing issue found while checking this** (not caused by the rule change above,
but surfaced by reviewing every client write to `videos/{id}`):
`video_feed_repository.dart`'s `video_interaction_service.dart` increments `viewCount`,
`shareCount`, and `engagementScore` on `videos/{id}` via `.set(..., SetOptions(merge: true))`,
called by *any* signed-in viewer, not just the video's owner. Firestore rules evaluate a merge-set
against an existing document as an `update`, and the **current, already-deployed** rule requires
`request.auth.uid == resource.data.userId` for `update` — so a non-owner viewer's engagement
increment should already be rejected with `permission-denied` today, independent of anything in
this doc. (`video_feed_repository.dart`'s `markBroken` even has a `catch (e) { if (e.code ==
'permission-denied') return; }` right next to a similar owner-gated write, suggesting this
failure mode is already known/tolerated somewhere in this codebase.) The rule change proposed
above doesn't make this worse — it only adds a status condition on top of the existing owner
check — but it's worth a separate look at whether view/share counters need their own
Cloud-Function-mediated increment path (matching how `videoEvents`/`videoStats` already work)
rather than a direct client write gated by ownership.

## 4. Schema notes

New fields creator-studio now writes onto `videos/{id}` pre-publish, via
`CreatorPublishService.mirrorProject`:

| Field | Type | Purpose |
|---|---|---|
| `projectId` | string | Same value as the doc id (`project.id`); explicit field per the creator-studio spec, redundant with the id but harmless |
| `rawPath` | string | Storage object path (`videos-raw/{userId}/{id}.mp4`); consumed by `processVideoUpload`'s doc-lookup query |
| `renderedSha256` | string | Checksum of the local FFmpeg render; re-checked by `publicationGate.ts` |
| `uploadObjectPath` | string | Same as `rawPath` today; kept as a separate field because `publicationGate.ts` already reads it under this name |
| `clipCount` | number | Timeline clip count at render time |
| `timelineDurationMs` | number | Rendered timeline duration |
| `outputValidated` | boolean | Set by the client after local render validation passes |
| `moderationStatus` | string | `'not_requested'` until the callable runs |
| `source` | string | `'creator-studio'`, distinguishes from legacy raw uploads |

These coexist with the legacy pipeline's own fields (`processingStatus`, `playbackReady`,
`hlsLowUrl`, `hlsStandardUrl`, `thumbnailUrl`, etc. — see `processVideoUpload.ts`,
`finalizeVideoPlaybackAssets.ts`) on the same document. No field-name collisions.

## 5. Migration

None needed. `creatorProjects` was never actually written to by any code path (confirmed by
repo-wide search before this refactor) — there is no data to migrate away from it.

## 6. Deployment commands

From repo root, after the above changes are implemented and reviewed (paths per `firebase.json`):

```bash
firebase deploy --only storage
firebase deploy --only firestore:rules
firebase deploy --only functions:publishCreatorVideo
```

Run the Compile-to-Green style checks for the functions package before deploying, per the
existing `backend/firebase_functions/package.json` scripts (`npm run lint && npm run build && npm
test`).
