import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { db, FieldValue } from '../shared/firebaseAdmin';
import { writeAuditLog } from './revenueAuditLogger';

export interface EarningRecord {
  amount: number;
  status: string;
  currency?: string;
}

export interface WalletTotals {
  pending: number;
  approved: number;
  paid: number;
  lifetime: number;
  available: number;
  currency: string;
}

/** Pure aggregation — no I/O, fully unit-testable. */
export function aggregateEarnings(earnings: EarningRecord[]): WalletTotals {
  let pending = 0;
  let approved = 0;
  let paid = 0;
  let lifetime = 0;
  let currency = 'KES';

  for (const e of earnings) {
    const amount = e.amount || 0;
    lifetime += amount;
    if (e.currency) currency = e.currency;
    if (e.status === 'pending') pending += amount;
    else if (e.status === 'approved') approved += amount;
    else if (e.status === 'paid') paid += amount;
  }

  return { pending, approved, paid, lifetime, available: approved, currency };
}

/** Reads all earnings for a creator, aggregates, and writes walletBalances. */
export async function recalculateWalletBalance(creatorId: string): Promise<void> {
  const snap = await db
    .collection('creatorEarnings')
    .where('creatorId', '==', creatorId)
    .get();

  const earnings: EarningRecord[] = snap.docs.map((d) => {
    const data = d.data();
    return {
      amount: (data.amount as number) || 0,
      status: (data.status as string) || 'pending',
      currency: data.currency as string | undefined,
    };
  });

  const totals = aggregateEarnings(earnings);

  await db.collection('walletBalances').doc(creatorId).set(
    {
      userId: creatorId,
      available: totals.available,
      pending: totals.pending,
      paid: totals.paid,
      lifetime: totals.lifetime,
      currency: totals.currency,
      lastUpdatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await writeAuditLog('wallet_updated', {
    creatorId,
    available: totals.available,
    pending: totals.pending,
    paid: totals.paid,
    lifetime: totals.lifetime,
    currency: totals.currency,
  });
}

/** Fires on every new creatorEarnings doc to keep wallet balance current. */
export const walletBalanceAggregator = onDocumentCreated(
  'creatorEarnings/{earningId}',
  async (event) => {
    const earning = event.data?.data();
    if (!earning?.creatorId) return;
    await recalculateWalletBalance(earning.creatorId as string);
  }
);
