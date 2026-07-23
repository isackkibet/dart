import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { db, FieldValue } from '../shared/firebaseAdmin';
import { writeAuditLog } from './revenueAuditLogger';

const MIN_PAYOUT_KES = 100;

export const triggerMpesaPayout = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Must be signed in');

  const { amountKes, phoneNumber } = request.data as {
    amountKes: number;
    phoneNumber: string;
  };

  if (!amountKes || amountKes < MIN_PAYOUT_KES) {
    throw new HttpsError(
      'invalid-argument',
      `Minimum payout is KES ${MIN_PAYOUT_KES}`,
    );
  }
  if (!phoneNumber || !/^\+2547\d{8}$/.test(phoneNumber)) {
    throw new HttpsError(
      'invalid-argument',
      'phoneNumber must be a valid Kenyan M-Pesa number (+2547XXXXXXXX)',
    );
  }

  // Check wallet has sufficient approved balance.
  // NOTE: this previously read/wrote a `wallets/{uid}` collection that
  // nothing else in the codebase ever populates — walletBalanceAggregator
  // and earningsStatusSync both write `walletBalances/{uid}`, and that is
  // what the Flutter WalletRepository reads. Reading `wallets` here made
  // `available` permanently 0 for every user, so every payout request
  // failed with "insufficient balance" regardless of real balance. Fixed
  // to read/write the same collection the rest of the revenue pipeline
  // uses.
  const walletRef = db.collection('walletBalances').doc(uid);
  const walletSnap = await walletRef.get();
  const wallet = walletSnap.data();
  const available = (wallet?.available as number) ?? 0;

  if (available < amountKes) {
    throw new HttpsError(
      'failed-precondition',
      `Insufficient balance: available KES ${available}, requested KES ${amountKes}`,
    );
  }

  // Idempotency: create payout doc and reserve funds atomically
  const payoutRef = db.collection('payouts').doc();
  await db.runTransaction(async (tx) => {
    const freshWallet = await tx.get(walletRef);
    const freshAvailable = (freshWallet.data()?.available as number) ?? 0;
    if (freshAvailable < amountKes) {
      throw new HttpsError('failed-precondition', 'Insufficient balance (re-checked)');
    }

    tx.set(payoutRef, {
      userId: uid,
      amountKes,
      phoneNumber,
      status: 'queued',
      provider: 'mpesa',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.set(
      walletRef,
      {
        available: FieldValue.increment(-amountKes),
        reserved: FieldValue.increment(amountKes),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  await writeAuditLog('payout_queued', {
    userId: uid,
    amountKes,
    payoutId: payoutRef.id,
    provider: 'mpesa',
  });

  return { payoutId: payoutRef.id, status: 'queued' };
});
