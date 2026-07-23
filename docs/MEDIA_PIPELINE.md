# Media Pipeline

1. Mobile uploads raw video to Firebase Storage.
2. `onVideoCreated` creates transcode and AI jobs.
3. Cloud Run transcoder creates HLS ABR variants.
4. Validator confirms manifest and segments.
5. Moderation runs.
6. Firestore `videos/{id}.status = live`.
7. Feed ranking begins.

Never expose raw unvalidated videos to feed.
