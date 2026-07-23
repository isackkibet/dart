import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const validateUltraLowLatencyFeed1O = onCall(
  { region: 'europe-west2', timeoutSeconds: 540, memory: '512MiB' },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError('permission-denied', 'Admin only');
    }

    const eligibleSnap = await db
      .collection('videos')
      .where('visibility', '==', 'public')
      .where('playbackReady', '==', true)
      .where('processingStatus', '==', 'ready')
      .where('broken', '==', false)
      .get();

    let missingThumbnail = 0;
    let missingHls = 0;

    for (const doc of eligibleSnap.docs) {
      const data = doc.data();
      if (!data.thumbnailUrl) missingThumbnail++;
      if (!data.hlsLowUrl || !data.hlsStandardUrl || !data.hlsHdUrl) {
        missingHls++;
      }
    }

    const diagnosticsSnap = await db
      .collection('videoPlaybackDiagnostics')
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();

    const diagnostics = diagnosticsSnap.docs.map((doc) => doc.data());
    const validLatencySamples = diagnostics
      .map((item) => Number(item.timeToFirstFrameMs ?? 0))
      .filter((value) => value > 0 && value < 9999);

    const averageTimeToFirstFrameMs =
      validLatencySamples.length === 0
        ? null
        : Math.round(
            validLatencySamples.reduce((sum, value) => sum + value, 0) /
              validLatencySamples.length,
          );

    return {
      ok: missingThumbnail === 0 && missingHls === 0,
      feedEligibleVideos: eligibleSnap.size,
      missingThumbnail,
      missingHls,
      diagnosticsChecked: diagnosticsSnap.size,
      averageTimeToFirstFrameMs,
      readyForPilot:
        missingThumbnail === 0 &&
        missingHls === 0 &&
        averageTimeToFirstFrameMs !== null &&
        averageTimeToFirstFrameMs <= 500,
    };
  },
);
