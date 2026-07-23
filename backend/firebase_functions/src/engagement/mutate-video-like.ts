import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();

export const mutateVideoLike = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const videoId = String(request.data?.videoId ?? "");
  const mutationId = String(request.data?.mutationId ?? "");
  const liked = request.data?.liked === true;

  if (!videoId || !mutationId) {
    throw new HttpsError(
      "invalid-argument",
      "videoId and mutationId are required."
    );
  }

  const mutationRef = db.collection("engagementMutations").doc(mutationId);
  const likeRef = db.collection("videoLikes").doc(`${videoId}_${userId}`);
  const countRef = db.collection("videoEngagement").doc(videoId);

  await db.runTransaction(async (transaction) => {
    const [mutationSnapshot, likeSnapshot] = await Promise.all([
      transaction.get(mutationRef),
      transaction.get(likeRef),
    ]);

    if (mutationSnapshot.exists) return;

    const alreadyLiked = likeSnapshot.exists;

    if (liked && !alreadyLiked) {
      transaction.set(likeRef, {
        videoId,
        userId,
        createdAt: FieldValue.serverTimestamp(),
      });
      transaction.set(
        countRef,
        { likes: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
    }

    if (!liked && alreadyLiked) {
      transaction.delete(likeRef);
      transaction.set(
        countRef,
        { likes: FieldValue.increment(-1), updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
    }

    transaction.set(mutationRef, {
      mutationId,
      videoId,
      userId,
      action: liked ? "like" : "unlike",
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
