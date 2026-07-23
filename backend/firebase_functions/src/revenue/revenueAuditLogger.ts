import { db, FieldValue } from '../shared/firebaseAdmin';

export async function writeAuditLog(
  event: string,
  data: Record<string, unknown>
): Promise<void> {
  await db.collection('revenueAuditLogs').add({
    event,
    ...data,
    timestamp: FieldValue.serverTimestamp(),
  });
}
