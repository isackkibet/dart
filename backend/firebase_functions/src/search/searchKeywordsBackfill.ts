import { onRequest } from 'firebase-functions/v2/https';
import { db, FieldValue } from '../shared/firebaseAdmin';
import { generateSearchKeywords } from './searchKeywordsGenerator';

const TARGETS = ['videos', 'creatorProfiles', 'liveSessions', 'businessAccounts'];

export const searchKeywordsBackfill = onRequest(
  { region: 'us-central1', timeoutSeconds: 540, memory: '1GiB' },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'POST required' });
      return;
    }

    const statusRef = db.collection('searchBackfillStatus').doc();
    await statusRef.set({
      id: statusRef.id,
      status: 'running',
      processed: 0,
      failed: 0,
      skipped: 0,
      startedAt: FieldValue.serverTimestamp(),
    });

    let processed = 0;
    let failed = 0;
    let skipped = 0;

    for (const collection of TARGETS) {
      const snap = await db.collection(collection).get();
      for (const doc of snap.docs) {
        try {
          const data = doc.data();
          const searchKeywords = generateSearchKeywords(data);
          if (searchKeywords.length === 0) {
            skipped++;
            continue;
          }
          await doc.ref.set(
            { searchKeywords, searchIndexedAt: FieldValue.serverTimestamp() },
            { merge: true },
          );
          processed++;
        } catch (error) {
          failed++;
          await db.collection('searchIndexAuditLogs').add({
            collection,
            docId: doc.id,
            action: 'failed',
            error: error instanceof Error ? error.message : String(error),
            createdAt: FieldValue.serverTimestamp(),
          });
        }
      }
    }

    await statusRef.update({
      status: 'completed',
      processed,
      failed,
      skipped,
      completedAt: FieldValue.serverTimestamp(),
    });

    res.json({ ok: true, processed, failed, skipped });
  },
);
