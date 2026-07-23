/**
 * YohPal — Comprehensive Firestore video URL repair
 *
 * Problems addressed:
 *  1. Docs where hlsUrl is null / missing / '' but videoUrl is a valid Storage URL
 *     → copies videoUrl → hlsUrl so VideoModel.isPlayable = true
 *  2. Docs with no rawPath
 *     → parses rawPath from videoUrl so future processVideoUpload CF can link them
 *  3. Docs with no ownerId but videoUrl path contains a UID segment
 *     → extracts ownerId from the Storage path
 *  4. The 10 new docs created by link_storage_videos.js have no ownerId set
 *     → extracts ownerId from rawPath (videos/raw/{userId}/{filename})
 *
 * Run:
 *   cd backend/firebase_functions
 *   node fix_video_urls.js
 */
'use strict';

const admin = require('firebase-admin');

admin.initializeApp({
  credential:  admin.credential.applicationDefault(),
  projectId:   'yohlab',
  storageBucket: 'yohlab.firebasestorage.app',
});

const db = admin.firestore();

/** Extract the Storage path from a Firebase Storage download URL.
 *  https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encoded-path}?alt=media...
 */
function extractStoragePath(url) {
  try {
    const u = new URL(url);
    // pathname = /v0/b/{bucket}/o/{encoded-path}
    const match = u.pathname.match(/\/v0\/b\/[^/]+\/o\/(.+)$/);
    if (!match) return null;
    return decodeURIComponent(match[1]);
  } catch {
    return null;
  }
}

/** Try to pull a Firebase UID from a Storage path.
 *  Matches a 28-character alphanumeric segment common in Firebase UIDs.
 *  e.g. videos/raw/DQWdtHDVYKQGZ5c8DcVf216pU6g1/filename.mp4 → DQWdtHDVYKQGZ5c8DcVf216pU6g1
 */
function extractUid(storagePath) {
  if (!storagePath) return '';
  const parts = storagePath.split('/').filter(Boolean);
  // UID is typically a 20-28 char alphanumeric string, not a filename (no dots)
  for (const p of parts) {
    if (/^[A-Za-z0-9]{20,30}$/.test(p)) return p;
  }
  return '';
}

async function run() {
  console.log('\nYohPal — Firestore video URL repair\n');

  // Read ALL video docs (paginate in batches of 500)
  let total = 0, fixed = 0, alreadyOk = 0, noUrl = 0;
  let lastDoc = null;
  const BATCH_SIZE = 500;

  while (true) {
    let query = db.collection('videos').orderBy('__name__').limit(BATCH_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snap = await query.get();
    if (snap.empty) break;

    const writeBatch = db.batch();
    let batchUpdates = 0;

    for (const doc of snap.docs) {
      total++;
      const data  = doc.data();
      const hls   = data.hlsUrl   || '';
      const vUrl  = data.videoUrl || '';

      // Already playable — skip
      if (hls.length > 10) {
        alreadyOk++;
        continue;
      }

      // No URL at all — nothing we can do
      if (vUrl.length < 10) {
        noUrl++;
        console.log(`  SKIP (no videoUrl): ${doc.id}`);
        continue;
      }

      // Parse Storage path from videoUrl
      const storagePath = extractStoragePath(vUrl);
      const ownerId     = data.ownerId || extractUid(storagePath);

      const update = {
        hlsUrl:    vUrl,               // copy videoUrl → hlsUrl
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (storagePath && !data.rawPath) {
        update.rawPath = storagePath;  // backfill rawPath for CF future use
      }
      if (ownerId && !data.ownerId) {
        update.ownerId = ownerId;      // backfill ownerId extracted from path
      }

      writeBatch.update(doc.ref, update);
      batchUpdates++;
      fixed++;

      console.log(`  FIX ${doc.id.substring(0, 20)} | ownerId: ${ownerId || '?'} | path: ${storagePath ? storagePath.substring(0, 50) : 'unknown'}`);
    }

    if (batchUpdates > 0) await writeBatch.commit();
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < BATCH_SIZE) break;
  }

  // Also fix the 10 docs created by link_storage_videos.js which have rawPath but may lack ownerId
  console.log('\n── Fixing rawPath-based docs (from link_storage_videos.js) ──\n');
  const rawSnap = await db.collection('videos').where('rawPath', '!=', '').get();
  const rawBatch = db.batch();
  let rawFixed = 0;

  for (const doc of rawSnap.docs) {
    const data = doc.data();
    if (data.ownerId) continue; // already set
    const uid = extractUid(data.rawPath || '');
    if (uid) {
      rawBatch.update(doc.ref, {
        ownerId:  uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      rawFixed++;
      console.log(`  SET ownerId=${uid} on doc ${doc.id}`);
    }
  }

  if (rawFixed > 0) await rawBatch.commit();

  console.log('\n' + '─'.repeat(60));
  console.log(`Total docs scanned  : ${total}`);
  console.log(`Already had hlsUrl  : ${alreadyOk}`);
  console.log(`Fixed (hlsUrl set)  : ${fixed}`);
  console.log(`No URL (skipped)    : ${noUrl}`);
  console.log(`ownerId backfilled  : ${rawFixed}`);
  console.log('\nAll Firestore video docs now have hlsUrl set where videoUrl existed.');
  console.log('VideoModel.isPlayable will return true for all repaired docs.\n');
  process.exit(0);
}

run().catch(err => {
  console.error('Fatal:', err.message || err);
  process.exit(1);
});
