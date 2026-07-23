"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.recordPlaybackDiagnostic = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
exports.recordPlaybackDiagnostic = (0, https_1.onCall)({ region: 'europe-west2' }, async (request) => {
    const userId = request.auth?.uid;
    if (!userId)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    const videoId = String(request.data?.videoId ?? '');
    if (!videoId)
        throw new https_1.HttpsError('invalid-argument', 'videoId required');
    await db.collection('videoPlaybackDiagnostics').add({
        userId,
        videoId,
        timeToFirstFrameMs: Number(request.data?.timeToFirstFrameMs ?? 0),
        preloadHit: Boolean(request.data?.preloadHit ?? false),
        preloadMiss: Boolean(request.data?.preloadMiss ?? false),
        bufferStart: request.data?.bufferStart ?? null,
        bufferEnd: request.data?.bufferEnd ?? null,
        playbackError: request.data?.playbackError ?? null,
        sourceUrlType: request.data?.sourceUrlType ?? 'unknown',
        networkType: request.data?.networkType ?? 'unknown',
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { ok: true };
});
