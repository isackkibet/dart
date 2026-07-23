import { db, FieldValue } from '../firebaseAdmin';
import { paginateQuery } from '../pagination';

export async function getAdCampaigns(params?: { status?: string; cursor?: string }) {
  let query: FirebaseFirestore.Query = db.collection('adCampaigns');
  if (params?.status) {
    query = query.where('status', '==', params.status);
  }
  return paginateQuery(query, params?.cursor);
}

export async function getAdRevenueShare() {
  const snap = await db
    .collection('adRevenueShare')
    .orderBy('createdAt', 'desc')
    .limit(100)
    .get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function updateAdCampaignStatus(params: {
  campaignId: string;
  status: 'approved' | 'rejected';
  actorUserId: string;
  reason?: string;
}) {
  const campaignRef = db.collection('adCampaigns').doc(params.campaignId);
  await campaignRef.update({
    status: params.status,
    reviewedBy: params.actorUserId,
    reviewReason: params.reason || '',
    reviewedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('adAuditLogs').add({
    campaignId: params.campaignId,
    action: `AD_CAMPAIGN_${params.status.toUpperCase()}`,
    actorUserId: params.actorUserId,
    reason: params.reason || '',
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
