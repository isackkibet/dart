'use strict';
/**
 * Backfill Phase 1L playback readiness on the 57 real HLS-transcoded videos.
 *
 * For each video that has HLS files in videos-hls/{videoId}/:
 *   - hlsLowUrl      = videos-hls/{videoId}/playlist_360p.m3u8
 *   - hlsStandardUrl = videos-hls/{videoId}/playlist_480p.m3u8
 *   - hlsHdUrl       = videos-hls/{videoId}/playlist_720p.m3u8
 *   - previewUrl     = same as hlsLowUrl (fastest start)
 *   - playbackReady  = true
 *   - processingStatus = 'ready'
 *   - visibility     = 'public'
 *   - broken         = false
 *   - engagementScore = (likesCount||likes||0)*10 + (viewsCount||views||0)
 *   - fileSize = Storage object size (bytes)
 */
const admin = require('firebase-admin');
admin.initializeApp({
  credential:    admin.credential.applicationDefault(),
  projectId:     'yohlab',
  storageBucket: 'yohlab.firebasestorage.app',
});
const db     = admin.firestore();
const bucket = admin.storage().bucket('yohlab.firebasestorage.app');
const BUCKET = 'yohlab.firebasestorage.app';
const BASE   = `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o`;

function hlsUrl(videoId, file) {
  return `${BASE}/${encodeURIComponent(`videos-hls/${videoId}/${file}`)}?alt=media`;
}

async function run() {
  console.log('\nPhase 1L — Backfilling playbackReady on HLS-transcoded videos\n');

  const [files] = await bucket.getFiles({ prefix: 'videos-hls/' });
  const videoIds = [...new Set(
    files
      .filter(f => f.name.endsWith('/master.m3u8'))
      .map(f => f.name.split('/')[1])
  )];
  console.log(`Found ${videoIds.length} videos with HLS in videos-hls/\n`);

  let updated = 0, skipped = 0, errors = 0;
  const BATCH = 400;
  let batch = db.batch();
  let ops = 0;

  for (const videoId of videoIds) {
    const docRef = db.collection('videos').doc(videoId);
    const snap = await docRef.get();
    if (!snap.exists) { skipped++; continue; }

    const data = snap.data();
    // Compute a basic engagement score so orderBy('engagementScore') has values
    const engagementScore =
      ((data.likesCount ?? data.likes ?? 0) * 10) +
      (data.viewsCount ?? data.views ?? 0);

    // Get file size from raw MP4 metadata
    let fileSize = data.fileSize ?? 0;
    if (!fileSize) {
      try {
        const [rawMeta] = await bucket
          .file(`videos-raw/${data.userId || data.ownerId || ''}/${videoId}.mp4`)
          .getMetadata();
        fileSize = Number(rawMeta.size ?? 0);
      } catch (_) {}
    }

    const update = {
      hlsLowUrl:       hlsUrl(videoId, 'playlist_360p.m3u8'),
      hlsStandardUrl:  hlsUrl(videoId, 'playlist_480p.m3u8'),
      hlsHdUrl:        hlsUrl(videoId, 'playlist_720p.m3u8'),
      previewUrl:      hlsUrl(videoId, 'playlist_360p.m3u8'),
      playbackReady:   true,
      processingStatus:'ready',
      visibility:      'public',
      broken:          false,
      engagementScore,
      fileSize,
      updatedAt:       admin.firestore.FieldValue.serverTimestamp(),
    };

    batch.update(docRef, update);
    ops++;
    updated++;
    console.log(`  ✓ ${videoId}  engScore=${engagementScore}  fileSize=${fileSize}`);

    if (ops >= BATCH) {
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  }

  if (ops > 0) await batch.commit();

  console.log('\n' + '─'.repeat(55));
  console.log(`Updated : ${updated}`);
  console.log(`Skipped : ${skipped}`);
  console.log(`Errors  : ${errors}`);
  console.log('\nAll real HLS videos now have:');
  console.log('  playbackReady=true  processingStatus=ready  visibility=public');
  console.log('  hlsLowUrl / hlsStandardUrl / hlsHdUrl / previewUrl\n');
  process.exit(0);
}
run().catch(e => { console.error(e.message); process.exit(1); });
