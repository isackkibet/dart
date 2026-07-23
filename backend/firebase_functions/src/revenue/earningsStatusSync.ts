import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { recalculateWalletBalance } from './walletBalanceAggregator';
import { writeAuditLog } from './revenueAuditLogger';

/**
 * Fires whenever a creatorEarnings document is updated.
 * Only acts on status transitions (pending→approved, approved→paid, etc.)
 * and recalculates the creator's walletBalances totals.
 */
export const earningsStatusSync = onDocumentUpdated(
  'creatorEarnings/{earningId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Skip if status didn't change — avoids unnecessary recalculation
    if (before.status === after.status) return;

    const creatorId = after.creatorId as string | undefined;
    if (!creatorId) return;

    await recalculateWalletBalance(creatorId);

    await writeAuditLog('earnings_status_updated', {
      earningId: event.params.earningId,
      creatorId,
      oldStatus: before.status as string,
      newStatus: after.status as string,
    });
  }
);
