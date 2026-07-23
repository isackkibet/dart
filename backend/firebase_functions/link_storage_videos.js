/**
 * YohPal — Storage → Firestore video URL backfill
 *
 * Run from backend/firebase_functions/:
 *   node link_storage_videos.js
 *
 * Uses Application Default Credentials (gcloud auth application-default login).
 * Requires: GOOGLE_APPLICATION_CREDENTIALS or gcloud ADC.
 */

'use strict';

const admin = require('firebase-admin');

const BUCKET_NAME  = 'yohlab.firebasestorage.app';
const RAW_PREFIX   = 'videos/raw/';
const THUMB_PREFIX = 'thumbnails/';
const VIDEO_EXTS   = ['.mp4', '.mov', '.webm', '.mkv', '.avi'];

// Init with ADC — works with gcloud auth application-default login
admin.initializeApp({
  credential:    admin.credential.applicationDefault(),
  storageBucket: BUCKET_NAME,
  projectId:     'yohlab',
});

const db     = admin.firestore();
const bucket = admin.storage().bucket(BUCKET_NAME);

function buildDownloadUrl(filePath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET_NAME}/o/${encodeURIComponent(filePath)}?alt=media&token=${token}`;
}

async function getOrCreateDownloadUrl(filePath) {
  const file = bucket.file(filePath);
  const [meta] = await file.getMetadata();
  let token = meta.metadata && meta.metadata.firebaseStorageDownloadTokens;

  if (!token) {
    // Generate a stable token so the URL never expires (revokeable from console)
    const { v4: uuid } = require('uuid');
    token = uuid();
    await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
  }

  return buildDownloadUrl(filePath, token);
}

function extractVideoId(filePath) {
  // Strip prefix: videos/raw/
  const rel   = filePath.replace(RAW_PREFIX, '');
  const parts = rel.split('/').filter(Boolean);
  const filename = parts[parts.length - 1];
  return filename.replace(/\.[^.]+$/, ''); // strip extension
}

async function findThumbnailUrl(videoId) {
  const candidates = [
    `${THUMB_PREFIX}${videoId}.jpg`,
    `${THUMB_PREFIX}${videoId}.jpeg`,
    `${THUMB_PREFIX}${videoId}.png`,
    `${THUMB_PREFIX}${videoId}/thumb.jpg`,
  ];
  for (const path of candidates) {
    const [exists] = await bucket.file(path).exists();
    if (exists) {
      try { return await getOrCreateDownloadUrl(path); } catch (_) { /* skip */ }
    }
  }
  return '';
}

async function run() {
  console.log('\nYohPal — Storage → Firestore video URL backfill');
  console.log(`Bucket : ${BUCKET_NAME}`);
  console.log(`Prefix : ${RAW_PREFIX}\n`);

  // ── Phase 1: scan Storage for raw video files ──────────────────────────────
  const [files] = await bucket.getFiles({ prefix: RAW_PREFIX });
  const videoFiles = files.filter(f =>
    VIDEO_EXTS.some(ext => f.name.toLowerCase().endsWith(ext))
  );

  console.log(`Found ${videoFiles.length} video file(s) in Storage under ${RAW_PREFIX}\n`);

  let created = 0, updated = 0, skipped = 0, errors = 0;

  for (const file of videoFiles) {
    const videoId = extractVideoId(file.name);
    if (!videoId) { errors++; continue; }

    console.log(`  ${file.name}`);
    console.log(`  videoId: ${videoId}`);

    try {
      const videoUrl = await getOrCreateDownloadUrl(file.name);
      const docRef   = db.collection('videos').doc(videoId);
      const snap     = await docRef.get();

      if (!snap.exists) {
        const thumbnailUrl = await findThumbnailUrl(videoId);
        await docRef.set({
          id:             videoId,
          ownerId:        '',
          ownerUsername:  '',
          caption:        '',
          hlsUrl:         videoUrl,
          videoUrl:       videoUrl,
          thumbnailUrl,
          rawPath:        file.name,
          status:         'live',
          visibility:     'public',
          views:          0,
          likes:          0,
          broken:         false,
          tags:           [],
          createdAt:      admin.firestore.FieldValue.serverTimestamp(),
          updatedAt:      admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`  → CREATED\n`);
        created++;
      } else {
        const data = snap.data();
        const existingHls = data.hlsUrl || '';

        if (existingHls.length > 10) {
          console.log(`  → SKIPPED (hlsUrl already set)\n`);
          skipped++;
          continue;
        }

        const updates = {
          videoUrl,
          hlsUrl:    videoUrl,
          status:    'live',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        if (!data.thumbnailUrl) {
          updates.thumbnailUrl = await findThumbnailUrl(videoId);
        }

        await docRef.update(updates);
        console.log(`  → UPDATED (hlsUrl was empty → linked to Storage URL)\n`);
        updated++;
      }
    } catch (err) {
      console.error(`  ERROR: ${err.message}\n`);
      errors++;
    }
  }

  // ── Phase 2: fix Firestore docs with videoUrl set but hlsUrl empty ─────────
  console.log('── Phase 2: fixing Firestore docs with videoUrl but empty hlsUrl ──\n');

  const snap2 = await db.collection('videos').where('hlsUrl', '==', '').get();
  let phase2 = 0;

  for (const doc of snap2.docs) {
    const data = doc.data();
    if (data.videoUrl && data.videoUrl.length > 10) {
      await doc.ref.update({
        hlsUrl:    data.videoUrl,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`  Copied videoUrl → hlsUrl: ${doc.id}`);
      phase2++;
    }
  }

  // ── Summary ────────────────────────────────────────────────────────────────
  console.log('\n' + '─'.repeat(55));
  console.log(`Storage scan : Created ${created}  Updated ${updated}  Skipped ${skipped}  Errors ${errors}`);
  console.log(`Firestore fix: ${phase2} docs updated (videoUrl → hlsUrl)`);
  console.log('\nURL format (web-playable):');
  console.log(`  https://firebasestorage.googleapis.com/v0/b/${BUCKET_NAME}/o/{encoded-path}?alt=media&token={token}`);
  console.log('\nDone.\n');
  process.exit(0);
}

run().catch(err => {
  console.error('Fatal:', err.message || err);
  process.exit(1);
});
