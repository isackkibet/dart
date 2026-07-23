'use strict';
/**
 * YohPal — Sync videos-raw Storage files → Firestore + video feed
 *
 * For every MP4 in videos-raw/{userId}/{videoId}.mp4 in Firebase Storage:
 *  1. Gets or creates a download token so the URL is playable in the app
 *  2. Checks if HLS was transcoded (videos-hls/{videoId}/master.m3u8 exists)
 *     → if yes, gets/creates token for the master.m3u8 so HLS plays
 *  3. Looks up existing Firestore doc in 'videos' collection
 *     → creates one if missing, updates hlsUrl/videoUrl/ownerId/timestamp if present
 *
 * Run:
 *   cd backend/firebase_functions
 *   node sync_storage_to_feed.js
 */

const admin = require('firebase-admin');
const { v4: uuid } = require('uuid');

admin.initializeApp({
  credential:    admin.credential.applicationDefault(),
  projectId:     'yohlab',
  storageBucket: 'yohlab.firebasestorage.app',
});

const db     = admin.firestore();
const bucket = admin.storage().bucket('yohlab.firebasestorage.app');
const BUCKET = 'yohlab.firebasestorage.app';

function storageUrl(path, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

async function ensureToken(file) {
  const [meta] = await file.getMetadata();
  let token = meta.metadata && meta.metadata.firebaseStorageDownloadTokens;
  if (!token) {
    token = uuid();
    await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
  }
  return token;
}

async function run() {
  console.log('\nYohPal — Syncing videos-raw Storage → Firestore video feed\n');

  // List all MP4s in videos-raw/
  const [rawFiles] = await bucket.getFiles({ prefix: 'videos-raw/' });
  const mp4s = rawFiles.filter(f => /\.mp4$/i.test(f.name));

  // Index which videoIds have HLS transcoded
  const [hlsFiles] = await bucket.getFiles({ prefix: 'videos-hls/' });
  const hlsMasters = new Map(); // videoId → file
  for (const f of hlsFiles) {
    if (f.name.endsWith('/master.m3u8')) {
      const videoId = f.name.split('/')[1];
      hlsMasters.set(videoId, f);
    }
  }

  console.log(`Found ${mp4s.length} MP4(s) in videos-raw/`);
  console.log(`Found ${hlsMasters.size} HLS-transcoded video(s) in videos-hls/\n`);

  let created = 0, updated = 0, skipped = 0, errors = 0;

  for (const file of mp4s) {
    const parts   = file.name.split('/').filter(Boolean);
    // videos-raw/{userId}/{videoId}.mp4
    const userId  = parts[1] ?? '';
    const filename = parts[2] ?? '';
    const videoId = filename.replace(/\.mp4$/i, '');

    if (!videoId || !userId) { errors++; continue; }

    console.log(`▶ ${videoId}  (user: ${userId})`);

    try {
      // Get/create raw MP4 download URL
      const rawToken = await ensureToken(file);
      const rawUrl   = storageUrl(file.name, rawToken);

      // Prefer HLS master.m3u8 if transcoded; otherwise fall back to raw MP4
      let playUrl = rawUrl;
      let hlsUrl  = rawUrl; // default: serve raw MP4 as the stream
      const masterFile = hlsMasters.get(videoId);
      if (masterFile) {
        // HLS exists — use Storage URL for master.m3u8
        // Note: segments use relative paths; this works if Storage rules allow read
        // on videos-hls/ OR if a CDN is in front.
        // For now we store the raw MP4 URL as reliable fallback; hlsPath keeps the CDN URL.
        const hlsToken = await ensureToken(masterFile);
        const m3u8Url  = storageUrl(masterFile.name, hlsToken);
        hlsUrl  = m3u8Url;  // let the player try HLS first
        playUrl = m3u8Url;
        console.log(`   HLS available: ${masterFile.name}`);
      }

      const docRef = db.collection('videos').doc(videoId);
      const snap   = await docRef.get();

      if (!snap.exists) {
        // Create a new Firestore document
        await docRef.set({
          id:           videoId,
          userId,
          ownerId:      userId,
          ownerUsername: '',
          caption:      '',
          hlsUrl:       playUrl,
          videoUrl:     rawUrl,
          thumbnailUrl: '',
          rawPath:      file.name,
          originalUrl:  file.name,
          status:       'live',
          visibility:   'public',
          views:        0,
          viewsCount:   0,
          likes:        0,
          likesCount:   0,
          broken:       false,
          tags:         [],
          timestamp:    admin.firestore.FieldValue.serverTimestamp(),
          updatedAt:    admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`   → CREATED\n`);
        created++;
      } else {
        const data = snap.data();
        const needsUpdate =
          !data.hlsUrl || data.hlsUrl.length < 10 ||
          !data.timestamp ||
          (!data.ownerId && !data.userId);

        if (!needsUpdate) {
          console.log(`   → SKIPPED (already complete)\n`);
          skipped++;
          continue;
        }

        const update = {
          videoUrl:  rawUrl,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        if (!data.hlsUrl || data.hlsUrl.length < 10) update.hlsUrl = playUrl;
        if (!data.timestamp)  update.timestamp = admin.firestore.FieldValue.serverTimestamp();
        if (!data.ownerId)    update.ownerId = userId;
        if (!data.userId)     update.userId  = userId;
        if (!data.rawPath)    update.rawPath = file.name;
        if (!data.originalUrl) update.originalUrl = file.name;

        await docRef.update(update);
        console.log(`   → UPDATED\n`);
        updated++;
      }
    } catch (err) {
      console.error(`   ERROR: ${err.message}\n`);
      errors++;
    }
  }

  console.log('─'.repeat(55));
  console.log(`Created : ${created}`);
  console.log(`Updated : ${updated}`);
  console.log(`Skipped : ${skipped}`);
  console.log(`Errors  : ${errors}`);
  console.log('\nAll synced videos now have:');
  console.log('  • hlsUrl  → playable Firebase Storage URL (with token)');
  console.log('  • timestamp → appears in video feed orderBy(timestamp)');
  console.log('  • ownerId + userId → creator identity in both schema formats');
  console.log('\nDone.\n');
  process.exit(0);
}

run().catch(err => {
  console.error('Fatal:', err.message || err);
  process.exit(1);
});
