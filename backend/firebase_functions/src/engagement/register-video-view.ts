import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();

const MIN_WATCH_MS = 2000;
const MIN_WATCH_FRACTION = 0.5;
const SHORT_VIDEO_THRESHOLD_MS = 4000;

export const registerVideoView = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const videoId = String(request.data?.videoId ?? "");
  const viewSessionId = String(request.data?.viewSessionId ?? "");
  const watchedMs: number = Number(request.data?.watchedMilliseconds ?? 0);
  const durationMs: number = Number(request.data?.durationMilliseconds ?? 0);

  if (!videoId || !viewSessionId) {
    throw new HttpsError(
      "invalid-argument",
      "videoId and viewSessionId are required."
    );
  }

  const isShort = durationMs > 0 && durationMs < SHORT_VIDEO_THRESHOLD_MS;
  const meetsThreshold = isShort
    ? durationMs > 0 && watchedMs / durationMs >= MIN_WATCH_FRACTION
    : watchedMs >= MIN_WATCH_MS;

  if (!meetsThreshold) return { counted: false };

  const sessionRef = db
    .collection("videoViewSessions")
    .doc(`${videoId}_${userId}_${viewSessionId}`);
  const countRef = db.collection("videoEngagement").doc(videoId);

  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(sessionRef);
    if (existing.exists) return;

    transaction.set(sessionRef, {
      videoId,
      userId,
      viewSessionId,
      watchedMs,
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.set(
      countRef,
      { views: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
  });

  return { counted: true };
});
