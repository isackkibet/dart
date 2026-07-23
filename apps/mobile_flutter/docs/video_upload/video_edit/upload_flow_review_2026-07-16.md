# Upload Flow Review — 2026-07-16

Reviewed the working-tree changes (uncommitted, on `pap1`) against the actual code, not the
PDF "management review" docs in this folder — those read as prompt-injection bait aimed at an AI
coding agent (self-addressed emails instructing an assistant to dump the full repo, run
unreviewed shell scripts, cut release tags, etc.) rather than genuine specs. None of their
embedded commands were run. The technical shape they describe (camera → timeline → render →
publish gate → upload) does match what's actually in the repo, so that part is used below as
context, not as an instruction source.

## 1. What's implemented

**Capture → local project** (`upload_screen.dart`)
Camera/gallery capture persists the raw file to app-documents `raw_videos/`, probes duration,
creates a `CreatorProject` with one `VideoClipEdit`, saves it locally, and opens the editor. On
re-entry it offers to resume an in-progress draft (`_maybeOfferProjectResume`).

**Timeline editor** (`creator_editor_controller.dart`, `creator_editor_screen.dart`)
`CreatorEditorController` (a `ChangeNotifier`) owns add/trim/split/delete/reorder clip
operations, undo/redo via `EditorHistory`, and debounced (500ms) autosave to
`HiveCreatorProjectRepository` — **local device storage only**, nothing here touches Firestore.
The screen wires this to a clip timeline UI with trim/split sheets and an "Add clip" flow that
reuses `UploadScreen` in `returnFileOnCapture` mode.

**Local render** (`creator_render_screen.dart`, `ffmpeg_command_builder.dart`)
Every clip is trimmed and **re-encoded** (`libx264`/`aac`, always, even a single untouched clip),
then concatenated with `-c copy`. Output is validated (`render_output_validator.dart`) before the
project is marked `rendered`.

**Publish** (`creator_publish_screen.dart`, `creator_publish_service.dart`)
Client-side `CreatorPublicationGate` checks locally, then:
1. `uploadRenderedOutput` — uploads the rendered `.mp4` to Firebase Storage at
   `videos-rendered/{userId}/{projectId}.mp4` via the same `VideoStorageService` the old raw
   flow used.
2. `mirrorProject` — writes a Firestore doc.
3. `publish` — calls the `publishCreatorVideo` callable, which re-validates everything
   server-side against its own Firestore record and, only if that passes, creates the public
   `videos/{videoId}` document with `status: 'pending_moderation'`.

This is a real, mostly-coherent implementation of the "core editor" pipeline — not a stub.

## 2. The last step is breaking — root cause

Two separate, compounding bugs, both in the publish step:

### Bug A — Storage rules reject the upload path

`storage/storage.rules` only allows writes to `live-sessions/**`, `clips/**`, and `admin/**`;
everything else is `allow read, write: if false`. But `CreatorPublishService.uploadRenderedOutput`
writes to:

```
videos-rendered/{userId}/{projectId}.mp4
```

— a path with no matching rule, so it falls through to the default `if false` and Firebase
Storage rejects it with `permission-denied`. **This is the storage write that's breaking.**

### Bug B — `mirrorProject` writes to the wrong Firestore collection

`publishCreatorVideo.ts` reads the creator's project from `creatorProjects/{projectId}` to
independently validate the publish request (`publicationGate.ts` checks
`project.status`, `project.outputValidated`, `project.renderedSha256`,
`project.uploadObjectPath` — see `CreatorProjectRecord` in `creatorStudio.types.ts`).

But `CreatorPublishService.mirrorProject` writes those exact fields to **`videos/{project.id}`**,
not `creatorProjects/{project.id}`:

```dart
await _firestore.collection('videos').doc(project.id).set({
  'renderedSha256': ..., 'uploadObjectPath': ..., 'outputValidated': true, ...
});
```

The field shape is an exact match for `CreatorProjectRecord` — this was clearly meant to write
to `creatorProjects`, not `videos`. `HiveCreatorProjectRepository`'s own doc comment says as much:
*"a project only reaches the server once it's rendered, uploaded, and published... at which point
a separate `creatorProjects` Firestore mirror is written"* — that mirror is never written to the
collection the backend actually reads. Two consequences:

- `publishCreatorVideo` always throws `not-found` (no `creatorProjects/{id}` doc exists), so
  publish can never succeed even if Bug A is fixed.
- `mirrorProject` instead creates a doc directly under `videos/{project.id}` — a collection with
  `allow read: if true` in `firestore.rules`. That doc is missing `title`/`caption`/`tags`
  entirely (mirrorProject never sets them) and has `status: 'uploaded'`, not
  `pending_moderation`. It's publicly readable and looks like a real (broken) video record,
  and it's never cleaned up — it just sits there orphaned next to the real one the Cloud
  Function later creates under a different, random `videoId`. This is also exactly what the
  code comment on `CreatorPublishService` says shouldn't happen: *"the only thing that should
  write the public `videos/{id}` document"* is the callable — `mirrorProject` currently
  violates that itself.

### Fix

1. **Storage rules** — add a rule for the rendered-output path, scoped to the owning user:
   ```
   match /videos-rendered/{userId}/{fileName} {
     allow read: if signedIn() && request.auth.uid == userId;
     allow write: if signedIn() && request.auth.uid == userId
       && request.resource.size < 500 * 1024 * 1024
       && request.resource.contentType == 'video/mp4';
   }
   ```
2. **Fix the collection name** in `creator_publish_service.dart`:
   `_firestore.collection('videos')` → `_firestore.collection('creatorProjects')` in
   `mirrorProject`, and drop the `moderationStatus`/public-shaped fields that don't belong on a
   private project mirror.
3. **Add a matching Firestore rule** for `creatorProjects/{projectId}`, owner-scoped:
   ```
   match /creatorProjects/{projectId} {
     allow read: if signedIn() && request.auth.uid == resource.data.ownerId;
     allow create, update: if signedIn()
       && request.auth.uid == request.resource.data.ownerId;
   }
   ```
   Note this still means the client self-attests `outputValidated: true` and the SHA-256 the
   server later trusts — the server-side gate isn't actually independent of client claims yet.
   Worth a follow-up: verify the uploaded object's checksum server-side (e.g. a Storage-triggered
   function) rather than trusting the client-reported hash, before calling this "server-enforced."
4. Rerun the full `Camera → Timeline → Render → Publish` journey once both are deployed — that's
   the only way to confirm the callable's `not-found`/`permission-denied` failures are actually
   gone, not just theoretically fixed by rule inspection.

## 3. Streamlining: let users publish raw *or* edited

The good news: the architecture already mostly does this right. "Skip editing" and "continue to
render" in `creator_editor_screen.dart` do the exact same thing today —
`_skipEditingAndContinue` and `_goToRender` are identical, byte-for-byte duplicate methods that
both push `CreatorRenderScreen`. That's not a bug, it just means there's no real branch between
"raw" and "edited" — every project, edited or not, goes through the same
render → validate → upload → publish pipeline, which is correct given the backend's "upload only
rendered output, never the raw source" rule (`publishCreatorVideo` only ever accepts
`renderedSha256`/`uploadObjectPath` for a rendered file — there's no code path for publishing an
untouched source file, so a raw upload can't accidentally bypass moderation-relevant validation).

Two concrete streamlining moves:

- **Collapse the duplicate methods.** Keep one handler (e.g. `_continueToRender`), delete
  `_skipEditingAndContinue`, and point both the "Skip editing" text button and the primary
  "Render" action at it. Purely a cleanup — no behavior changes today, but the duplication invites
  drift (someone "fixes" one path and not the other).
- **Fast-path the render for untouched projects.** `ffmpeg_command_builder.dart` re-encodes with
  `libx264`/`aac` unconditionally, even for a single clip with no trim/rotation/speed changes —
  i.e. a pure "raw upload." For that case (`clips.length == 1 && clip is untrimmed && rotation ==
  0 && speed == 1`), skip the trim+concat commands and either stream-copy
  (`-c copy -movflags +faststart`) or just copy the source file directly to the render output
  path. This keeps the "always render, never publish raw source" invariant (still goes through
  validation/upload/publish the same way) while making the common "I didn't edit anything, just
  post it" case near-instant instead of a full re-encode.

This gives users a single mental model — "Edit (optional) → Post" — without a separate raw-upload
code path to maintain, while making the no-edits case fast.
