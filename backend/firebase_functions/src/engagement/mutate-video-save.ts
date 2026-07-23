import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();

export const mutateVideoSave = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const videoId = String(request.data?.videoId ?? "");
  const mutationId = String(request.data?.mutationId ?? "");
  const saved = request.data?.saved === true;

  if (!videoId || !mutationId) {
    throw new HttpsError(
      "invalid-argument",
      "videoId and mutationId are required."
    );
  }

  const mutationRef = db.collection("engagementMutations").doc(mutationId);
  const saveRef = db.collection("videoSaves").doc(`${videoId}_${userId}`);
  const countRef = db.collection("videoEngagement").doc(videoId);

  await db.runTransaction(async (transaction) => {
    const [mutationSnapshot, saveSnapshot] = await Promise.all([
      transaction.get(mutationRef),
      transaction.get(saveRef),
    ]);

    if (mutationSnapshot.exists) return;

    const alreadySaved = saveSnapshot.exists;

    if (saved && !alreadySaved) {
      transaction.set(saveRef, {
        videoId,
        userId,
        createdAt: FieldValue.serverTimestamp(),
      });
      transaction.set(
        countRef,
        { saves: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
    }

    if (!saved && alreadySaved) {
      transaction.delete(saveRef);
      transaction.set(
        countRef,
        { saves: FieldValue.increment(-1), updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
    }

    transaction.set(mutationRef, {
      mutationId,
      videoId,
      userId,
      action: saved ? "save" : "unsave",
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  const updated = await countRef.get();
  return (
    updated.data() ?? {
      views: 0,
      likes: 0,
      comments: 0,
      shares: 0,
      saves: 0,
      gifts: 0,
    }
  );
});
