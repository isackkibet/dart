/**
 * One-time script: scans videos-hls/ in Firebase Storage, finds every master
 * playlist (.m3u8), and creates (or updates) a Firestore `videos` document so
 * those videos appear in the app feed.
 *
 * Run:
 *   cd backend/firebase_functions
 *   npx ts-node --project tsconfig.json ../scripts/register_hls_videos.ts
 */

import * as admin from 'firebase-admin';
import * as serviceAccount from '../../serviceAccountKey.json';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
  storageBucket: 'yohlab.firebasestorage.app',
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

const HLS_PREFIX = 'videos-hls/';
// Adjust this to match your actual folder structure.
// Common patterns:
//   videos-hls/{videoId}/master.m3u8
//   videos-hls/{userId}/{videoId}/master.m3u8
const MASTER_PLAYLIST_NAMES = ['master.m3u8', 'index.m3u8', 'playlist.m3u8'];

function buildPublicUrl(filePath: string): string {
  const encoded = encodeURIComponent(filePath);
  return `https://firebasestorage.googleapis.com/v0/b/yohlab.firebasestorage.app/o/${encoded}?alt=media`;
}

async function run() {
  console.log(`Listing all files under ${HLS_PREFIX} ...`);
  const [files] = await bucket.getFiles({ prefix: HLS_PREFIX });

  // Find every master playlist file
  const masterFiles = files.filter(f =>
    MASTER_PLAYLIST_NAMES.some(name => f.name.endsWith(`/${name}`) || f.name.endsWith(name))
  );

  console.log(`Found ${masterFiles.length} master playlist(s).\n`);

  let created = 0;
  let updated = 0;
  let skipped = 0;

  for (const file of masterFiles) {
    const parts = file.name.split('/').filter(Boolean);
    // parts[0] = 'videos-hls'
    // parts[1] = videoId  (single-level structure)
    // OR parts[1]=userId, parts[2]=videoId  (two-level structure)
    // Detect by checking how many parts exist before the filename
    const videoId = parts.length === 3
      ? parts[1]           // videos-hls/{videoId}/master.m3u8
      : parts.length === 4
        ? parts[2]         // videos-hls/{userId}/{videoId}/master.m3u8
        : parts[1];        // fallback

    const hlsUrl = buildPublicUrl(file.name);
    console.log(`  ${file.name} → videoId: ${videoId}`);
    console.log(`  hlsUrl: ${hlsUrl}`);

    const ref = db.collection('videos').doc(videoId);
    const snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        id: videoId,
        ownerId: '',
        userId: '',
        title: videoId,
        description: '',
        hlsUrl,
        hlsManifestUrl: hlsUrl,
        videoUrl: hlsUrl,
        thumbnailUrl: '',
        status: 'live',
        visibility: 'public',
        views: 0,
        likes: 0,
        engagementScore: 0,
        broken: false,
        tags: [],
        rawPath: file.name,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`  → CREATED\n`);
      created++;
    } else {
      const data = snap.data()!;
      if (!data.hlsUrl || data.hlsUrl === '') {
        await ref.update({
          hlsUrl,
          hlsManifestUrl: hlsUrl,
          videoUrl: hlsUrl,
          status: 'live',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`  → UPDATED (hlsUrl was empty)\n`);
        updated++;
      } else {
        console.log(`  → SKIPPED (already has hlsUrl: ${data.hlsUrl})\n`);
        skipped++;
      }
    }
  }

  console.log(`\nDone. Created: ${created}  Updated: ${updated}  Skipped: ${skipped}`);
  process.exit(0);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
