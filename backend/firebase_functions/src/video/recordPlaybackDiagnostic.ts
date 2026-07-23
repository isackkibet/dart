import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const db = getFirestore();

export const recordPlaybackDiagnostic = onCall(
  { region: 'europe-west2' },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) throw new HttpsError('unauthenticated', 'Sign in required');

    const videoId = String(request.data?.videoId ?? '');
    if (!videoId) throw new HttpsError('invalid-argument', 'videoId required');

    await db.collection('videoPlaybackDiagnostics').add({
      userId,
      videoId,
      timeToFirstFrameMs: Number(request.data?.timeToFirstFrameMs ?? 0),
      preloadHit:         Boolean(request.data?.preloadHit  ?? false),
      preloadMiss:        Boolean(request.data?.preloadMiss ?? false),
      bufferStart:        request.data?.bufferStart  ?? null,
      bufferEnd:          request.data?.bufferEnd    ?? null,
      playbackError:      request.data?.playbackError ?? null,
      sourceUrlType:      request.data?.sourceUrlType ?? 'unknown',
      networkType:        request.data?.networkType   ?? 'unknown',
      createdAt:          FieldValue.serverTimestamp(),
    });

    return { ok: true };
  },
);
