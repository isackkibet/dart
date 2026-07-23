import { db } from '../firebaseAdmin';

export async function getCreatorWalletSummary(creatorId: string) {
  const balanceSnap = await db
    .collection('walletBalances')
    .where('creatorId', '==', creatorId)
    .limit(1)
    .get();
  const ledgerSnap = await db
    .collection('walletLedger')
    .where('creatorId', '==', creatorId)
    .limit(100)
    .get();
  return {
    balance: balanceSnap.empty ? null : { id: balanceSnap.docs[0].id, ...balanceSnap.docs[0].data() },
    transactions: ledgerSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
  };
}
