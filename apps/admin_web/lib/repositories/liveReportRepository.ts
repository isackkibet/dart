import { db, FieldValue } from '../firebaseAdmin';

export async function getLiveReports() {
  const snap = await db
    .collection('liveReports')
    .where('status', '==', 'open')
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function resolveLiveReport(params: {
  reportId: string;
  action: 'approved' | 'rejected' | 'escalated';
  actorUserId: string;
  reason?: string;
}) {
  const reportRef = db.collection('liveReports').doc(params.reportId);
  const auditRef = db.collection('liveAuditLogs').doc();
  await db.runTransaction(async (tx) => {
    tx.update(reportRef, {
      status: params.action,
      reviewedBy: params.actorUserId,
      reviewReason: params.reason || '',
      reviewedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(auditRef, {
      reportId: params.reportId,
      action: `LIVE_REPORT_${params.action.toUpperCase()}`,
      actorUserId: params.actorUserId,
      reason: params.reason || '',
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { ok: true };
}
