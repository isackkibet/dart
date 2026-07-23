#!/usr/bin/env node
/**
 * upload_video.js — Ingest a local video file into the YohPal production pipeline.
 *
 * Usage:
 *   node upload_video.js <videoFilePath> [creatorId] [creatorUsername] [description]
 *
 * Pipeline:
 *   1. Transcode to HLS 360p / 480p / 720p + thumbnail via ffmpeg
 *   2. Upload HLS files → Storage: videos-hls/{videoId}/
 *   3. Upload original   → Storage: videos/{videoId}/original.mp4
 *   4. Upload thumbnail  → Storage: thumbnails/{videoId}.jpeg
 *   5. Rewrite variant playlists so every segment URL is cdn.stream.yohpal.com
 *   6. Write Firestore doc in videos/{videoId}
 *
 * Requires: ffmpeg in PATH, ADC or GOOGLE_APPLICATION_CREDENTIALS set
 */

'use strict';

const path = require('path');
const fs   = require('fs');
const os   = require('os');
const { execFile, execFileSync } = require('child_process');
const { promisify } = require('util');
const execFileAsync = promisify(execFile);

const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');

// ── Config ────────────────────────────────────────────────────────────────────
const BUCKET       = 'yohlab.firebasestorage.app';
const CDN_BASE_HLS = 'https://cdn.stream.yohpal.com/videos-hls';
const STORAGE_ORIGIN = 'firebasestorage.googleapis.com';

// HLS transcode settings (mirrors hls.service.ts exactly)
const VARIANTS = [
  { label: '360p', width: 640,  height: 360,  bitrate: '800k'  },
  { label: '480p', width: 854,  height: 480,  bitrate: '1200k' },
  { label: '720p', width: 1280, height: 720,  bitrate: '2500k' },
];

// ── Bootstrap ─────────────────────────────────────────────────────────────────
if (!getApps().length) initializeApp();
const db      = getFirestore();
const storage = getStorage().bucket(BUCKET);

// ── Helpers ───────────────────────────────────────────────────────────────────
function log(msg)  { process.stdout.write(`  ${msg}\n`); }
function ok(msg)   { process.stdout.write(`  ✔ ${msg}\n`); }
function fail(msg) { process.stderr.write(`  ✘ ${msg}\n`); process.exit(1); }
function step(msg) { process.stdout.write(`\n[${msg}]\n`); }

function randomId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  return Array.from({ length: 20 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

async function ffmpeg(args) {
  const { stdout, stderr } = await execFileAsync('ffmpeg', ['-y', ...args]).catch(e => {
    throw new Error(`ffmpeg error: ${e.stderr || e.message}`);
  });
  return { stdout, stderr };
}

/** Upload a local file to Storage and return a Firebase download token URL. */
async function uploadFile(localPath, storagePath, contentType) {
  // Generate a download token so we get the same URL format as the client SDK
  // without needing a service-account signing key.
  const token = require('crypto').randomUUID();
  await storage.upload(localPath, {
    destination: storagePath,
    metadata: {
      contentType,
      cacheControl: 'public,max-age=31622400',
      metadata: { firebaseStorageDownloadTokens: token },
    },
  });
  const encoded = encodeURIComponent(storagePath);
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encoded}?alt=media&token=${token}`;
}

/** Rewrite all Firebase Storage segment URLs in a variant playlist to CDN. */
function rewritePlaylistToCdn(content, videoId) {
  const rewritten = content.split('\n').map(line => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return line;
    // segment filenames are relative (e.g. v360p_000.ts) or absolute storage URLs
    if (trimmed.includes(STORAGE_ORIGIN)) {
      const filename = trimmed.split('/').pop().split('?')[0];
      return `${CDN_BASE_HLS}/${videoId}/${filename}`;
    }
    // already CDN or relative — leave alone
    return line;
  }).join('\n');

  if (rewritten.includes(STORAGE_ORIGIN)) {
    throw new Error('Playlist still contains firebasestorage.googleapis.com after rewrite');
  }
  return rewritten;
}

/** Build master.m3u8 pointing to CDN variant playlists. */
function buildMasterManifest(videoId) {
  const base = `${CDN_BASE_HLS}/${videoId}`;
  return [
    '#EXTM3U',
    '#EXT-X-VERSION:3',
    '',
    '#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360,CODECS="avc1.42c014,mp4a.40.2"',
    `${base}/playlist_360p.m3u8`,
    '#EXT-X-STREAM-INF:BANDWIDTH=1200000,RESOLUTION=854x480,CODECS="avc1.42c015,mp4a.40.2"',
    `${base}/playlist_480p.m3u8`,
    '#EXT-X-STREAM-INF:BANDWIDTH=2500000,RESOLUTION=1280x720,CODECS="avc1.42c01e,mp4a.40.2"',
    `${base}/playlist_720p.m3u8`,
  ].join('\n') + '\n';
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  const [,, videoFilePath, creatorId = 'admin', creatorUsername = 'yohpal', description = ''] = process.argv;

  if (!videoFilePath) {
    fail('Usage: node upload_video.js <videoFilePath> [creatorId] [creatorUsername] [description]');
  }
  if (!fs.existsSync(videoFilePath)) {
    fail(`File not found: ${videoFilePath}`);
  }

  const videoId = randomId();
  const workDir = path.join(os.tmpdir(), `yohpal_${videoId}`);
  fs.mkdirSync(workDir, { recursive: true });

  console.log('\n═══════════════════════════════════════════════════════');
  console.log(' YohPal Video Upload Pipeline');
  console.log('═══════════════════════════════════════════════════════');
  log(`Video ID    : ${videoId}`);
  log(`Source      : ${videoFilePath}`);
  log(`Creator     : ${creatorId} (@${creatorUsername})`);
  log(`Work dir    : ${workDir}`);

  // ── Step 1: Thumbnail ───────────────────────────────────────────────────────
  step('1/6  Generating thumbnail');
  const thumbPath = path.join(workDir, 'thumbnail.jpeg');
  await ffmpeg([
    '-i', videoFilePath,
    '-ss', '00:00:01',
    '-vframes', '1',
    '-vf', 'scale=480:-1',
    '-q:v', '3',
    thumbPath,
  ]);
  ok(`Thumbnail → ${thumbPath}`);

  // ── Step 2: Transcode HLS variants ─────────────────────────────────────────
  step('2/6  Transcoding HLS variants');
  for (const v of VARIANTS) {
    const playlistPath = path.join(workDir, `playlist_${v.label}.m3u8`);
    const segmentPath  = path.join(workDir, `v${v.label}_%03d.ts`);
    log(`  → ${v.label} (${v.width}×${v.height} @ ${v.bitrate})`);
    await ffmpeg([
      '-i', videoFilePath,
      '-vf', `scale=${v.width}:${v.height}:force_original_aspect_ratio=decrease,pad=${v.width}:${v.height}:(ow-iw)/2:(oh-ih)/2`,
      '-c:v', 'libx264',
      '-preset', 'veryfast',
      '-pix_fmt', 'yuv420p',
      '-profile:v', 'main',
      '-level', '3.1',
      '-b:v', v.bitrate,
      '-maxrate', v.bitrate,
      '-bufsize', '2M',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-hls_time', '2',
      '-hls_playlist_type', 'vod',
      '-hls_segment_filename', segmentPath,
      playlistPath,
    ]);
    ok(`  ${v.label} done`);
  }

  // ── Step 3: Rewrite segment URLs to CDN ────────────────────────────────────
  step('3/6  Rewriting segment URLs to CDN');
  for (const v of VARIANTS) {
    const playlistPath = path.join(workDir, `playlist_${v.label}.m3u8`);
    const raw = fs.readFileSync(playlistPath, 'utf8');
    const rewritten = rewritePlaylistToCdn(raw, videoId);
    fs.writeFileSync(playlistPath, rewritten, 'utf8');
    ok(`  playlist_${v.label}.m3u8 rewritten`);
  }
  // Write master manifest (always CDN-absolute)
  const masterPath = path.join(workDir, 'master.m3u8');
  fs.writeFileSync(masterPath, buildMasterManifest(videoId), 'utf8');
  ok('  master.m3u8 written');

  // ── Step 4: Upload HLS to Storage ─────────────────────────────────────────
  step('4/6  Uploading HLS files to Firebase Storage');
  const hlsFiles = fs.readdirSync(workDir).filter(f => f.endsWith('.m3u8') || f.endsWith('.ts'));
  log(`  ${hlsFiles.length} files to upload`);

  for (const file of hlsFiles) {
    const localPath   = path.join(workDir, file);
    const storagePath = `videos-hls/${videoId}/${file}`;
    const contentType = file.endsWith('.m3u8') ? 'application/vnd.apple.mpegurl' : 'video/MP2T';
    await storage.upload(localPath, {
      destination: storagePath,
      metadata: { contentType, cacheControl: 'public,max-age=31622400' },
    });
  }
  ok(`  Uploaded ${hlsFiles.length} HLS files → gs://${BUCKET}/videos-hls/${videoId}/`);

  // ── Step 5: Upload original + thumbnail ────────────────────────────────────
  step('5/6  Uploading original video + thumbnail');
  const origStoragePath  = `videos/${videoId}/original.mp4`;
  const thumbStoragePath = `thumbnails/${videoId}.jpeg`;

  log('  Uploading original...');
  const originalUrl = await uploadFile(videoFilePath, origStoragePath, 'video/mp4');
  ok(`  Original → gs://${BUCKET}/${origStoragePath}`);

  log('  Uploading thumbnail...');
  const thumbnailUrl = await uploadFile(thumbPath, thumbStoragePath, 'image/jpeg');
  ok(`  Thumbnail → gs://${BUCKET}/${thumbStoragePath}`);

  // ── Step 6: Write Firestore document ──────────────────────────────────────
  step('6/6  Writing Firestore document');
  const now = new Date();
  const cdnMasterUrl = `${CDN_BASE_HLS}/${videoId}/master.m3u8`;

  const doc = {
    userId:                   creatorId,
    uploaderId:               creatorId,
    userName:                 creatorUsername,
    fullName:                 creatorUsername,
    ownerUsername:            creatorUsername,
    uploaderUsername:         creatorUsername,
    uploaderUsernameLowercase: creatorUsername.toLowerCase(),
    uploaderStatus:           'active',

    videoUrl:      originalUrl,
    hlsUrl:        originalUrl,
    hlsPath:       cdnMasterUrl,
    filePath:      origStoragePath,
    rawPath:       origStoragePath,
    thumbnail:     thumbnailUrl,
    audioUrl:      '',
    audioName:     '',
    description:   description || '',

    status:            'live',
    processingStatus:  'ready',
    playbackReady:     true,
    visibility:        'public',
    privacy:           'Everyone',
    audience:          false,
    allowComments:     true,
    flagged:           false,
    broken:            false,

    tags:           [],
    searchKeywords: [],
    engagementScore: 0,
    likesCount:     0,
    bookmarksCount: 0,
    downloadsCount: 0,
    commentsCount:  0,
    sharesCount:    0,
    viewsCount:     0,

    timestamp:            FieldValue.serverTimestamp(),
    processingStartedAt:  now,
    processingFinishedAt: now,
    updatedAt:            now,
  };

  await db.collection('videos').doc(videoId).set(doc);
  ok(`  Firestore videos/${videoId} written`);

  // ── Summary ─────────────────────────────────────────────────────────────────
  console.log('\n═══════════════════════════════════════════════════════');
  console.log(' Upload complete');
  console.log('═══════════════════════════════════════════════════════');
  log(`Video ID    : ${videoId}`);
  log(`HLS master  : ${cdnMasterUrl}`);
  log(`360p        : ${CDN_BASE_HLS}/${videoId}/playlist_360p.m3u8`);
  log(`480p        : ${CDN_BASE_HLS}/${videoId}/playlist_480p.m3u8`);
  log(`720p        : ${CDN_BASE_HLS}/${videoId}/playlist_720p.m3u8`);
  log(`Thumbnail   : ${thumbStoragePath}`);
  log(`Firestore   : videos/${videoId}`);
  console.log('═══════════════════════════════════════════════════════\n');

  // Cleanup work dir
  fs.rmSync(workDir, { recursive: true, force: true });
}

main().catch(e => {
  process.stderr.write(`\nFATAL: ${e.message}\n`);
  process.exit(1);
});
