import { db, FieldValue } from '../shared/firebaseAdmin';

export async function assertAiRateLimit(userId: string): Promise<void> {
  const today = new Date().toISOString().slice(0, 10);
  const ref = db.collection('aiUsageDaily').doc(`${userId}_${today}`);

  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    const count = doc.exists ? Number(doc.data()?.count ?? 0) : 0;
    const maxDaily = Number(process.env.AI_DAILY_JOB_LIMIT ?? 50);

    if (count >= maxDaily) {
      throw new Error('Daily AI job limit reached');
    }

    tx.set(
      ref,
      {
        userId,
        date: today,
        count: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}
