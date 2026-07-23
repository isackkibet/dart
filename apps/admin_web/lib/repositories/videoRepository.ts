import { db, FieldValue } from '../firebaseAdmin';
import { paginateQuery } from '../pagination';

export type VideoVisibility = 'public' | 'hidden' | 'restricted' | 'deleted';

export async function getVideos(params?: {
  status?: string;
  visibility?: string;
  creatorUserId?: string;
  limit?: number;
  cursor?: string;
}) {
  let query: FirebaseFirestore.Query = db.collection('videos');
  if (params?.status) query = query.where('status', '==', params.status);
  if (params?.visibility) query = query.where('visibility', '==', params.visibility);
  if (params?.creatorUserId) query = query.where('userId', '==', params.creatorUserId);
  return paginateQuery(query, params?.cursor, params?.limit || 50);
}

export async function getBrokenVideos() {
  const snap = await db
    .collection('videos')
    .where('status', 'in', ['transcode_failed', 'processing_failed', 'broken'])
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function updateVideoVisibility(params: {
  videoId: string;
  visibility: VideoVisibility;
  actorUserId: string;
  reason?: string;
}) {
  const videoRef = db.collection('videos').doc(params.videoId);
  const auditRef = db.collection('videoAuditLogs').doc();
  await db.runTransaction(async (tx) => {
    tx.update(videoRef, {
      visibility: params.visibility,
      ...(params.visibility === 'deleted' ? { status: 'deleted' } : {}),
      adminReason: params.reason || '',
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(auditRef, {
      videoId: params.videoId,
      action: `VIDEO_${params.visibility.toUpperCase()}`,
      actorUserId: params.actorUserId,
      reason: params.reason || '',
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { ok: true };
}

export async function requeueAiVideoJob(params: {
  jobId: string;
  actorUserId: string;
  reason?: string;
}) {
  const jobRef = db.collection('aiVideoJobs').doc(params.jobId);
  const auditRef = db.collection('videoAuditLogs').doc();
  await db.runTransaction(async (tx) => {
    tx.update(jobRef, {
      status: 'pending',
      attempts: 0,
      adminRequeuedBy: params.actorUserId,
      adminRequeueReason: params.reason || '',
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(auditRef, {
      jobId: params.jobId,
      action: 'AI_VIDEO_JOB_REQUEUED',
      actorUserId: params.actorUserId,
      reason: params.reason || '',
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { ok: true };
}
