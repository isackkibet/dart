import { onObjectFinalized } from 'firebase-functions/v2/storage';
import { logger } from 'firebase-functions/v2';
import { db, FieldValue } from '../shared/firebaseAdmin';
import { extractThumbnailFromVideo } from './extractVideoThumbnail';

// Handles both upload path conventions:
//   videos-raw/{userId}/{videoId}.mp4   (Flutter app — primary)
//   videos/raw/{userId}/{filename}.mp4  (legacy path)
export const processVideoUpload = onObjectFinalized({ region: 'europe-west2' }, async (event) => {
  const objectPath = event.data.name;
  const isHyphenPath = objectPath?.startsWith('videos-raw/');
  const isSlashPath  = objectPath?.startsWith('videos/raw/');
  if (!isHyphenPath && !isSlashPath) return;

  const token = event.data.metadata?.firebaseStorageDownloadTokens;
  const downloadUrl = token
    ? `https://firebasestorage.googleapis.com/v0/b/${event.data.bucket}/o/${encodeURIComponent(objectPath)}?alt=media&token=${token}`
    : '';

  // Extract userId:  videos-raw/{userId}/{file} → parts[1]
  //                  videos/raw/{userId}/{file}  → parts[2]
  const parts  = objectPath.split('/').filter(Boolean);
  const userId = isHyphenPath ? (parts[1] ?? '') : (parts[2] ?? '');

  // Derive videoId from filename (strip extension)
  const filename = parts[parts.length - 1];
  const videoId  = filename.replace(/\.[^.]+$/, '');

  // Find Firestore doc: rawPath → originalUrl → videoId (filename match)
  let docRef: FirebaseFirestore.DocumentReference | null = null;

  const byRawPath = await db.collection('videos').where('rawPath', '==', objectPath).limit(1).get();
  if (!byRawPath.empty) {
    docRef = byRawPath.docs[0].ref;
  } else {
    const byOrigUrl = await db.collection('videos').where('originalUrl', '==', objectPath).limit(1).get();
    if (!byOrigUrl.empty) {
      docRef = byOrigUrl.docs[0].ref;
    } else {
      const byId = await db.collection('videos').doc(videoId).get();
      if (byId.exists) docRef = byId.ref;
    }
  }

  if (!docRef) return;

  // Look up ownerUsername from users collection so it appears immediately in feed
  let ownerUsername = '';
  if (userId) {
    try {
      const userDoc = await db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        const u = userDoc.data()!;
        ownerUsername = (u['userName'] as string | undefined) ||
                        (u['username'] as string | undefined) ||
                        (u['displayName'] as string | undefined) ||
                        [u['firstName'], u['lastName']].filter(Boolean).join(' ') ||
                        '';
      }
    } catch (_) {}
  }

  // Read existing doc to avoid overwriting caption/title already set by the app
  const existingSnap = await docRef.get();
  const existing = existingSnap.data() ?? {};
  const caption = (existing['caption'] as string | undefined) ||
                  (existing['title']   as string | undefined) || '';

  const update: Record<string, unknown> = {
    // Playback readiness — video is the raw MP4, plays immediately
    status:           'live',
    processingStatus: 'ready',
    playbackReady:    true,
    broken:           false,
    visibility:       'public',
    // URL fields
    hlsUrl:           downloadUrl,
    videoUrl:         downloadUrl,
    rawPath:          objectPath,
    // Metadata
    caption,
    fileSize:         Number(event.data.size ?? 0),
    updatedAt:        FieldValue.serverTimestamp(),
  };

  if (userId) {
    update['ownerId'] = userId;
    update['userId']  = userId;
  }
  if (ownerUsername) {
    update['ownerUsername'] = ownerUsername;
  }

  await docRef.update(update);

  try {
    const thumbnailUrl = await extractThumbnailFromVideo({
      videoPath: objectPath,
      outputPath: `video-thumbnails/${videoId}/thumbnail.jpg`,
    });
    await docRef.set(
      {
        thumbnailUrl,
        playbackReady: true,
        processingStatus: 'ready',
        broken: false,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  } catch (err) {
    logger.error(`Thumbnail extraction failed for video ${videoId}`, err);
  }
});
