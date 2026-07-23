import { db, FieldValue } from '../firebaseAdmin';
import { paginateQuery } from '../pagination';

export async function getAiVideoJobs(params?: { status?: string; cursor?: string }) {
  let query: FirebaseFirestore.Query = db.collection('aiVideoJobs');
  if (params?.status) {
    query = query.where('status', '==', params.status);
  }
  return paginateQuery(query, params?.cursor);
}

export async function requeueAiVideoJob(params: {
  jobId: string;
  actorUserId: string;
  reason?: string;
}) {
  await db.collection('aiVideoJobs').doc(params.jobId).update({
    status: 'pending',
    attempts: 0,
    adminRequeuedBy: params.actorUserId,
    adminRequeueReason: params.reason || '',
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('aiJobLogs').add({
    jobId: params.jobId,
    action: 'AI_VIDEO_JOB_REQUEUED',
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
