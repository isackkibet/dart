import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { extractThumbnailFromVideo } from './extractVideoThumbnail';

const db = admin.firestore();

export const backfillVideoThumbnails = onCall(
  { region: 'europe-west2', timeoutSeconds: 540, memory: '1GiB' },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError('permission-denied', 'Admin only');
    }

    const snap = await db
      .collection('videos')
      .where('status', '==', 'live')
      .get();

    let updated = 0;
    let skipped = 0;
    let failed = 0;

    for (const doc of snap.docs) {
      const data = doc.data();
      if (data.thumbnailUrl) {
        skipped++;
        continue;
      }
      try {
        const videoPath = data.rawPath || data.storagePath || data.originalStoragePath;
        if (!videoPath) {
          skipped++;
          continue;
        }
        const thumbnailUrl = await extractThumbnailFromVideo({
          videoPath,
          outputPath: `video-thumbnails/${doc.id}/thumbnail.jpg`,
        });
        await doc.ref.set({ thumbnailUrl }, { merge: true });
        updated++;
      } catch (_) {
        failed++;
      }
    }

    return { ok: true, updated, skipped, failed };
  },
);
