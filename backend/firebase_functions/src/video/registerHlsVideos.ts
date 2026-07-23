import { onCall } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, FieldValue } from '../shared/firebaseAdmin';

const BUCKET = 'yohlab.firebasestorage.app';
const HLS_PREFIX = 'videos-hls/';
const MASTER_NAMES = ['master.m3u8', 'index.m3u8', 'playlist.m3u8'];

function publicUrl(filePath: string): string {
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(filePath)}?alt=media`;
}

export const registerHlsVideos = onCall(
  { region: 'europe-west2', timeoutSeconds: 300, memory: '512MiB' },
  async () => {
    const bucket = admin.storage().bucket(BUCKET);
    const [files] = await bucket.getFiles({ prefix: HLS_PREFIX });

    const masters = files.filter(f =>
      MASTER_NAMES.some(name => f.name.endsWith(`/${name}`) || f.name === name)
    );

    const results: { path: string; videoId: string; action: string }[] = [];

    for (const file of masters) {
      const parts = file.name.split('/').filter(Boolean);
      // parts[0] = 'videos-hls'
      // two possible layouts:
      //   videos-hls/{videoId}/master.m3u8          → parts.length == 3
      //   videos-hls/{userId}/{videoId}/master.m3u8 → parts.length == 4
      const videoId = parts.length >= 4 ? parts[2] : parts[1];
      const hlsUrl = publicUrl(file.name);

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
          rawPath: file.name,
          status: 'live',
          visibility: 'public',
          views: 0,
          likes: 0,
          engagementScore: 0,
          broken: false,
          tags: [],
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        results.push({ path: file.name, videoId, action: 'created' });
      } else {
        const data = snap.data()!;
        if (!data.hlsUrl) {
          await ref.update({
            hlsUrl,
            hlsManifestUrl: hlsUrl,
            videoUrl: hlsUrl,
            status: 'live',
            updatedAt: FieldValue.serverTimestamp(),
          });
          results.push({ path: file.name, videoId, action: 'updated' });
        } else {
          results.push({ path: file.name, videoId, action: 'skipped' });
        }
      }
    }

    return { scanned: masters.length, results };
  }
);
