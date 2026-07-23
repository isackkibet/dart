# Video Editing Before Posting — Implemented vs. Pending

Companion to [ROADMAP_SUMMARY.md](./ROADMAP_SUMMARY.md), scoped narrowly to one question: once a
creator has a video (recorded or picked from the gallery), what can they actually *do* to it
before it goes out — and how does that compare to what the roadmap specs call for?

Findings below are from reading the current codebase directly (`apps/mobile_flutter/lib`), not
from the planning docs' own status claims — several of those have been shown elsewhere in this
project to be optimistic about what's real.

## The one-line answer

**There is no video editing capability before posting today.** A creator can play back what they
recorded/picked and attach a title, caption, and hashtags. Nothing about the video file itself —
its frames, audio, length, or appearance — can be changed in-app.

## What "before posting" actually looks like right now

```
Capture / gallery pick
        │
        ▼
Preview screen  ──  playback only: tap to pause, scrub bar, no cuts, no filters
        │
        ▼
Publish form  ──  Title, Caption, Hashtags (text fields in a bottom sheet)
        │
        ▼
Upload  ──  the exact file recorded/picked is the exact file that gets uploaded, byte for byte
```

No frame of the video is ever touched, re-encoded, or re-rendered client-side between capture and
upload. This isn't a partial implementation of editing — it's the complete absence of one.

## Feature-by-feature: spec vs. reality

| Capability | Where it's specified | Status | What's actually there |
|---|---|---|---|
| Trim / split / merge / reorder clips | 1.1A full spec §*, RC1 build sequence | **Not implemented** | No timeline data model, no clip list, no FFmpeg (or any) client-side video-processing package in `pubspec.yaml`. |
| Crop / rotate / speed per clip | 1.1A full spec | **Not implemented** | No such controls anywhere in `lib/`. |
| Undo/redo editing history | 1.1A full spec, RC1 | **Not implemented** | No editor session/history state exists to undo. |
| Filters, LUTs, beauty, background removal, green screen | 1.1A vision doc capability matrix | **Not implemented** | Confirmed still on the "Missing" list from the original codebase assessment; nothing has changed since. |
| Music library, beat sync, ducking, voice-over, audio mixing | 1.1A phase 2 ("Caption and Audio Pilot") | **Not implemented** | No audio-track model, no music picker, no mixing service. |
| Captions burned into the video / styled subtitle overlay | 1.1A phase 2, 1.1B "AI Subtitle Engine" | **Not implemented** | See below — captions exist only as a *text field*, never composited onto a frame. |
| Text overlays, stickers, transitions, duet/stitch, templates | 1.1A vision doc capability matrix | **Not implemented** | No such widgets or models anywhere. |
| Draft / project persistence with edit history | 1.1A full spec — Hive-based `CreatorProject`, autosave, version history | **Not implemented as specified** | `hive` isn't a dependency at all. What exists instead: a much smaller `VideoDraftService` (SharedPreferences, one JSON blob) that remembers a local file path + the title/caption/hashtags text if a creator backs out before publishing. It has no concept of an edit — there's nothing to autosave *of* an edit. |
| Publication gate enforcing edit/moderation completeness before publish | 1.1A/RC1 `PublicationGate` / `VideoPublicationGate` | **Not implemented** | Publish proceeds as soon as a title is entered. No moderation step, no compliance check, no gate of any kind sits between "tap Publish" and the video going live. |
| AI-assisted editing (captions, hooks, hashtags, thumbnail ideas, trim suggestions, viral score) | 1.1B "AI Production Engine" — meant to be *execution*, not suggestions | **Implemented, but as text-only suggestions, and currently unreachable** | `video_editor_ai/` is a real, working feature: it generates caption text, hashtag lists, hook lines, a viral-score number, thumbnail *ideas* (text descriptions, not images), and trim *suggestions* (timestamps as advice). Every one of these `apply*` methods (`ai_publish_repository.dart`) writes a text/metadata field to the Firestore video document — none of them touch the video file. `AiTrimService.generateTrimSuggestions()`, for example, only creates an AI job requesting advice; nothing moves a timeline handle or re-renders anything. Separately: **`AiEditorScreen` has zero navigation entry points anywhere in the app right now** — it's registered in `router.dart` but nothing pushes to it, so even this suggestion-only tool isn't reachable by a creator today. |
| Privacy Shield (face/voice blurring) | RC2 design + implementation specs | **Not implemented** | No detection, tracking, or anonymization code exists anywhere in the client or backend. |
| Ecosystem objects (Jobs/Market/etc.) attached during editing | 1.1A phase 3 | **Not implemented in the edit flow** | A `TimelineOverlayScreen` does exist (`lib/features/commerce/`), but it's a *viewer*-facing "Shop / Book / Apply" surface for tapping objects on an already-published video — not a creator tool for attaching objects while editing. Different feature, same word "timeline." |

## What's actually solid in the surrounding flow

Not everything is a gap — the steps immediately before and after editing are in reasonably good
shape, which is worth naming so the picture isn't read as universally bad:

- **Capture and selection** — a real in-app camera (front/rear switch, permission handling,
  lifecycle-safe dispose/reinit) plus gallery picking, unified in one screen.
- **Upload reliability** — real `UploadTask` progress, cancel, and retry; a 250MB / file-type
  guard; a lightweight draft that survives backing out mid-flow.
- **Publishing metadata** — title, caption, and hashtags are collected and actually reach the
  video document with consistent field names (`caption`, `tags`) that the feed model reads.

These make the *ends* of the pipeline (get a file in, get it published) functional. The entire
*middle* — everything a "video editing suite" implies — is the gap.

## Reading this against the roadmap's own build order

RC1's stated safest build order is: **camera/timeline → drafts/rendering → reliable upload →
captions/audio → ecosystem objects → AI integration → controlled pilot → wider rollout.**

Mapped to what actually exists: camera (done, capture-only — no timeline half), reliable upload
(done), everything from "drafts/rendering" through "AI integration" in the *editing* sense
(timeline, captions-as-overlay, audio, ecosystem objects during edit) — not started. AI
integration exists, but as the suggestion-only, currently-unreachable layer described above, not
the execution layer 1.1B calls for.
