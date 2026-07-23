import * as functions from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
export const mediaWorkerDispatch = functions.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.HttpsError("unauthenticated", "Authentication required.");
  }
  const { sessionId, creatorId, jobType, inputUrl } = request.data || {};
  if (!sessionId || !creatorId || !jobType || !inputUrl) {
    throw new functions.HttpsError("invalid-argument", "Missing required job fields.");
  }
  if (request.auth.uid !== creatorId) {
    throw new functions.HttpsError("permission-denied", "Creator mismatch.");
  }
  const ref = admin.firestore().collection("mediaWorkerJobs").doc();
  await ref.set({
    sessionId,
    creatorId,
    jobType,
    inputUrl,
    status: "queued",
    retryCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {
    jobId: ref.id,
    status: "queued",
  };
});
export const retryMediaWorkerJob = functions.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.HttpsError("unauthenticated", "Authentication required.");
  }
  const { jobId } = request.data || {};
  if (!jobId) {
    throw new functions.HttpsError("invalid-argument", "jobId is required.");
  }
  const ref = admin.firestore().collection("mediaWorkerJobs").doc(jobId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new functions.HttpsError("not-found", "Job not found.");
  }
  const job = snap.data()!;
  if (job.creatorId !== request.auth.uid) {
    throw new functions.HttpsError("permission-denied", "Not job owner.");
  }
  await ref.update({
    status: "queued",
    retryCount: admin.firestore.FieldValue.increment(1),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {
    jobId,
    status: "queued",
  };
});
