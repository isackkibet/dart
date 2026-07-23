import { db, FieldValue } from '../firebaseAdmin';

export async function getSupportTickets(params?: { status?: string }) {
  let query: FirebaseFirestore.Query = db.collection('supportTickets');
  if (params?.status) {
    query = query.where('status', '==', params.status);
  }
  const snap = await query.orderBy('createdAt', 'desc').limit(100).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function assignSupportTicket(params: {
  ticketId: string;
  assignedTo: string;
  actorUserId: string;
}) {
  await db.collection('supportTickets').doc(params.ticketId).update({
    assignedTo: params.assignedTo,
    status: 'assigned',
    assignedBy: params.actorUserId,
    assignedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('supportAuditLogs').add({
    ticketId: params.ticketId,
    action: 'TICKET_ASSIGNED',
    assignedTo: params.assignedTo,
    actorUserId: params.actorUserId,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}

export async function resolveSupportTicket(params: {
  ticketId: string;
  actorUserId: string;
  resolution?: string;
}) {
  await db.collection('supportTickets').doc(params.ticketId).update({
    status: 'resolved',
    resolvedBy: params.actorUserId,
    resolution: params.resolution || '',
    resolvedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('supportAuditLogs').add({
    ticketId: params.ticketId,
    action: 'TICKET_RESOLVED',
    resolution: params.resolution || '',
    actorUserId: params.actorUserId,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
}
