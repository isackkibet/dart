"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processVideoUpload = void 0;
const storage_1 = require("firebase-functions/v2/storage");
const v2_1 = require("firebase-functions/v2");
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
const extractVideoThumbnail_1 = require("./extractVideoThumbnail");
// Handles upload path conventions:
//   liveVideos/{videoId}.mp4            (Flutter app — new liveVideos pipeline)
//   videos-raw/{userId}/{videoId}.mp4   (Flutter app — legacy)
//   videos/raw/{userId}/{filename}.mp4  (legacy path)
exports.processVideoUpload = (0, storage_1.onObjectFinalized)({ region: 'europe-west2' }, async (event) => {
    const objectPath = event.data.name;
    const isLivePath = objectPath?.startsWith('liveVideos/');
    const isHyphenPath = objectPath?.startsWith('videos-raw/');
    const isSlashPath = objectPath?.startsWith('videos/raw/');
    if (!isLivePath && !isHyphenPath && !isSlashPath)
        return;
    const token = event.data.metadata?.firebaseStorageDownloadTokens;
    const downloadUrl = token
        ? `https://firebasestorage.googleapis.com/v0/b/${event.data.bucket}/o/${encodeURIComponent(objectPath)}?alt=media&token=${token}`
        : '';
    // Extract userId:
    //   liveVideos/{videoId}.mp4        → no userId (flat layout)
    //   videos-raw/{userId}/{file}      → parts[1]
    //   videos/raw/{userId}/{file}      → parts[2]
    const parts = objectPath.split('/').filter(Boolean);
    const userId = isLivePath ? ''
        : isHyphenPath ? (parts[1] ?? '')
            : (parts[2] ?? '');
    // Derive videoId from filename (strip extension)
    const filename = parts[parts.length - 1];
    const videoId = filename.replace(/\.[^.]+$/, '');
    // Route to the correct Firestore collection based on upload path
    const collectionName = isLivePath ? 'liveVideos' : 'videos';
    // Find Firestore doc: rawPath → originalUrl → videoId (filename match)
    let docRef = null;
    const byRawPath = await firebaseAdmin_1.db.collection(collectionName).where('rawPath', '==', objectPath).limit(1).get();
    if (!byRawPath.empty) {
        docRef = byRawPath.docs[0].ref;
    }
    else {
        const byOrigUrl = await firebaseAdmin_1.db.collection(collectionName).where('originalUrl', '==', objectPath).limit(1).get();
        if (!byOrigUrl.empty) {
            docRef = byOrigUrl.docs[0].ref;
        }
        else {
            const byId = await firebaseAdmin_1.db.collection(collectionName).doc(videoId).get();
            if (byId.exists)
                docRef = byId.ref;
        }
    }
    if (!docRef)
        return;
    // Look up ownerUsername from users collection so it appears immediately in feed
    let ownerUsername = '';
    if (userId) {
        try {
            const userDoc = await firebaseAdmin_1.db.collection('users').doc(userId).get();
            if (userDoc.exists) {
                const u = userDoc.data();
                ownerUsername = u['userName'] ||
                    u['username'] ||
                    [u['firstName'], u['lastName']].filter(Boolean).join(' ') ||
                    '';
            }
        }
        catch (_) { }
    }
    // Read existing doc to avoid overwriting caption/title already set by the app
    const existingSnap = await docRef.get();
    const existing = existingSnap.data() ?? {};
    const caption = existing['caption'] ||
        existing['title'] || '';
    const update = {
        // Playback readiness — video is the raw MP4, plays immediately
        status: 'live',
        processingStatus: 'ready',
        playbackReady: true,
        broken: false,
        visibility: 'public',
        // URL fields
        hlsUrl: downloadUrl,
        videoUrl: downloadUrl,
        rawPath: objectPath,
        // Metadata
        caption,
        fileSize: Number(event.data.size ?? 0),
        updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    };
    if (userId) {
        update['ownerId'] = userId;
        update['userId'] = userId;
    }
    if (ownerUsername) {
        update['ownerUsername'] = ownerUsername;
    }
    await docRef.update(update);
    // Enqueue CDN-ready HLS transcode job for liveVideos/ uploads.
    // The ffmpeg_worker Cloud Run service polls mediaJobs and produces
    // multi-bitrate HLS in liveVideos-hls/{videoId}/ with CDN cache headers.
    if (isLivePath) {
        const bucket = event.data.bucket;
        await firebaseAdmin_1.db.collection('mediaJobs').add({
            jobType: 'hls_transcode',
            videoId,
            collection: collectionName,
            inputRef: `gs://${bucket}/${objectPath}`,
            outputPrefix: `gs://${bucket}/liveVideos-hls/${videoId}`,
            status: 'queued',
            priority: 10,
            createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
    }
    try {
        const thumbnailUrl = await (0, extractVideoThumbnail_1.extractThumbnailFromVideo)({
            videoPath: objectPath,
            outputPath: `video-thumbnails/${videoId}/thumbnail.jpg`,
        });
        await docRef.set({
            thumbnailUrl,
            playbackReady: true,
            processingStatus: 'ready',
            broken: false,
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        }, { merge: true });
    }
    catch (err) {
        v2_1.logger.error(`Thumbnail extraction failed for video ${videoId}`, err);
    }
});
