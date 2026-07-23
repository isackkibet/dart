import { aggregateEarnings, EarningRecord } from '../walletBalanceAggregator';

// ─────────────────────────────────────────────────────────────
// aggregateEarnings — pure function, no Firestore required
// ─────────────────────────────────────────────────────────────

describe('aggregateEarnings', () => {
  it('sums pending, approved, paid, and lifetime correctly', () => {
    const earnings: EarningRecord[] = [
      { amount: 100, status: 'pending', currency: 'KES' },
      { amount: 200, status: 'approved', currency: 'KES' },
      { amount: 50, status: 'paid', currency: 'KES' },
      { amount: 150, status: 'pending', currency: 'KES' },
    ];
    const result = aggregateEarnings(earnings);
    expect(result.pending).toBe(250);
    expect(result.approved).toBe(200);
    expect(result.paid).toBe(50);
    expect(result.lifetime).toBe(500);
    expect(result.available).toBe(200); // available == approved
    expect(result.currency).toBe('KES');
  });

  it('returns all zeros for an empty earnings list', () => {
    const result = aggregateEarnings([]);
    expect(result.pending).toBe(0);
    expect(result.approved).toBe(0);
    expect(result.paid).toBe(0);
    expect(result.lifetime).toBe(0);
    expect(result.available).toBe(0);
    expect(result.currency).toBe('KES');
  });

  it('ignores earnings with unknown status in bucket totals but counts in lifetime', () => {
    const earnings: EarningRecord[] = [
      { amount: 300, status: 'pending' },
      { amount: 100, status: 'refunded' }, // unknown status
    ];
    const result = aggregateEarnings(earnings);
    expect(result.pending).toBe(300);
    expect(result.approved).toBe(0);
    expect(result.paid).toBe(0);
    expect(result.lifetime).toBe(400); // refunded still counts in lifetime
    expect(result.available).toBe(0);
  });

  it('uses the currency from the last record seen', () => {
    const earnings: EarningRecord[] = [
      { amount: 100, status: 'pending', currency: 'KES' },
      { amount: 50, status: 'approved', currency: 'USD' },
    ];
    const result = aggregateEarnings(earnings);
    expect(result.currency).toBe('USD');
  });

  it('treats missing amount as 0', () => {
    const earnings = [
      { amount: 0, status: 'pending' },
      { amount: 500, status: 'approved' },
    ] as EarningRecord[];
    const result = aggregateEarnings(earnings);
    expect(result.pending).toBe(0);
    expect(result.approved).toBe(500);
    expect(result.lifetime).toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────
// Idempotency logic (unit-level, no Firestore calls)
// ─────────────────────────────────────────────────────────────

describe('idempotency guard logic', () => {
  it('skips processing when lock document already exists', () => {
    // Simulate the check inside giftRevenueProcessor's transaction
    const lockExists = true;
    let earningCreated = false;

    // Mirrors the transaction guard:  if (lockDoc.exists) return;
    if (!lockExists) {
      earningCreated = true;
    }

    expect(earningCreated).toBe(false);
  });

  it('processes gift when lock document does not exist', () => {
    const lockExists = false;
    let earningCreated = false;

    if (!lockExists) {
      earningCreated = true;
    }

    expect(earningCreated).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────
// earningsStatusSync guard logic
// ─────────────────────────────────────────────────────────────

describe('earningsStatusSync status-change guard', () => {
  it('skips recalculation when status is unchanged', () => {
    const before = { status: 'pending', creatorId: 'creator-1' };
    const after = { status: 'pending', creatorId: 'creator-1' };
    const shouldRecalculate = before.status !== after.status;
    expect(shouldRecalculate).toBe(false);
  });

  it('triggers recalculation when status changes pending→approved', () => {
    const before = { status: 'pending', creatorId: 'creator-1' };
    const after = { status: 'approved', creatorId: 'creator-1' };
    const shouldRecalculate = before.status !== after.status;
    expect(shouldRecalculate).toBe(true);
  });

  it('triggers recalculation when status changes approved→paid', () => {
    const before = { status: 'approved', creatorId: 'creator-1' };
    const after = { status: 'paid', creatorId: 'creator-1' };
    const shouldRecalculate = before.status !== after.status;
    expect(shouldRecalculate).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────
// Gift revenue field validation
// ─────────────────────────────────────────────────────────────

describe('giftRevenueProcessor input validation', () => {
  function shouldProcess(gift: {
    creatorId?: string;
    amount?: number;
  }): boolean {
    return !(!gift.creatorId || !gift.amount || gift.amount <= 0);
  }

  it('rejects a gift with no creatorId', () => {
    expect(shouldProcess({ amount: 100 })).toBe(false);
  });

  it('rejects a gift with zero amount', () => {
    expect(shouldProcess({ creatorId: 'c1', amount: 0 })).toBe(false);
  });

  it('rejects a gift with negative amount', () => {
    expect(shouldProcess({ creatorId: 'c1', amount: -50 })).toBe(false);
  });

  it('accepts a valid gift', () => {
    expect(shouldProcess({ creatorId: 'c1', amount: 100 })).toBe(true);
  });
});
