"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.finalizeVideoPlaybackAssets = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const db = (0, firestore_2.getFirestore)();
exports.finalizeVideoPlaybackAssets = (0, firestore_1.onDocumentUpdated)({ document: 'videos/{videoId}', region: 'europe-west2' }, async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after)
        return;
    const videoId = event.params.videoId;
    // Trigger only when processingStatus reaches 'transcoded'
    if (after.processingStatus !== 'transcoded')
        return;
    // Avoid re-running if already finalised
    if (after.playbackReady === true)
        return;
    const required = [
        after.thumbnailUrl,
        after.previewUrl,
        after.hlsLowUrl,
        after.hlsStandardUrl,
    ];
    const ready = required.every((v) => typeof v === 'string' && v.length > 0);
    if (!ready)
        return;
    await db.collection('videos').doc(videoId).set({
        playbackReady: true,
        processingStatus: 'ready',
        broken: false,
        playbackFinalizedAt: firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
    await db.collection('videoProcessingLogs').add({
        videoId,
        action: 'playback_ready',
        createdAt: firestore_2.FieldValue.serverTimestamp(),
    });
});
