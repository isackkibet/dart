'use strict';
/**
 * YohPal — Rewrite HLS m3u8 manifests to use CDN URLs
 *
 * Rewrites all playlist references from relative paths or Firebase Storage URLs
 * to cdn.stream.yohpal.com, ensuring ExoPlayer resolves segments via CDN cache
 * rather than origin storage.
 *
 * Run:
 *   cd backend/firebase_functions
 *   node rewrite_hls_manifests.js
 */

const admin = require('firebase-admin');

admin.initializeApp({
  credential:    admin.credential.applicationDefault(),
  projectId:     'yohlab',
  storageBucket: 'yohlab.firebasestorage.app',
});

const bucket = admin.storage().bucket('yohlab.firebasestorage.app');
const CDN_BASE       = 'https://cdn.stream.yohpal.com';
const STORAGE_ORIGIN = 'https://firebasestorage.googleapis.com';

function hlsFileUrl(videoId, fileName) {
  return `${CDN_BASE}/videos-hls/${videoId}/${fileName}`;
}

async function rewriteManifest(videoId, fileName) {
  const file = bucket.file(`videos-hls/${videoId}/${fileName}`);
  const [exists] = await file.exists();
  if (!exists) return false;

  const [raw] = await file.download();
  const original = raw.toString('utf8');

  // Rewrite every reference to CDN; replace Firebase Storage URLs too
  const rewritten = original.split('\n').map(line => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return line;
    if (trimmed.startsWith(`${CDN_BASE}/`)) return line; // already CDN
    if (trimmed.startsWith(STORAGE_ORIGIN)) {
      // Extract filename from Storage URL: .../o/videos-hls%2FvideoId%2FfileName?alt=media
      const match = trimmed.match(/\/o\/([^?]+)/);
      if (match) {
        const decoded = decodeURIComponent(match[1]);
        const fileName = decoded.split('/').pop();
        return hlsFileUrl(videoId, fileName);
      }
    }
    if (trimmed.startsWith('http')) return line; // unknown absolute URL — leave
    return hlsFileUrl(videoId, trimmed);
  }).join('\n');

  if (rewritten.includes(STORAGE_ORIGIN)) {
    throw new Error(`CDN rewrite incomplete for ${videoId}/${fileName} — firebasestorage.googleapis.com still present`);
  }

  if (rewritten === original) return false; // nothing changed

  await file.save(rewritten, {
    metadata: {
      contentType: 'application/vnd.apple.mpegurl',
      cacheControl: 'public, max-age=3600',
    },
    resumable: false,
  });
  return true;
}

async function run() {
  console.log('\nYohPal — Rewriting HLS m3u8 manifests to absolute Storage URLs\n');

  const [files] = await bucket.getFiles({ prefix: 'videos-hls/' });
  const masters = files.filter(f => f.name.endsWith('/master.m3u8'));

  console.log(`Found ${masters.length} videos with HLS in videos-hls/\n`);

  let rewritten = 0, skipped = 0, errors = 0;

  for (const masterFile of masters) {
    const videoId = masterFile.name.split('/')[1];
    const playlists = ['master.m3u8', 'playlist_360p.m3u8', 'playlist_480p.m3u8', 'playlist_720p.m3u8'];

    process.stdout.write(`  ${videoId} ... `);
    let changed = 0;

    try {
      for (const pl of playlists) {
        const updated = await rewriteManifest(videoId, pl);
        if (updated) changed++;
      }
      if (changed > 0) {
        console.log(`rewrote ${changed} playlist(s)`);
        rewritten++;
      } else {
        console.log('already absolute, skipped');
        skipped++;
      }
    } catch (err) {
      console.log(`ERROR: ${err.message}`);
      errors++;
    }
  }

  console.log('\n' + '─'.repeat(55));
  console.log(`Rewritten : ${rewritten} videos`);
  console.log(`Skipped   : ${skipped} videos (already absolute)`);
  console.log(`Errors    : ${errors}`);
  console.log('\nHLS streams now route all segments through cdn.stream.yohpal.com.');
  console.log('ExoPlayer will resolve every segment URL via CDN cache.\n');
  process.exit(0);
}

run().catch(err => {
  console.error('Fatal:', err.message || err);
  process.exit(1);
});
