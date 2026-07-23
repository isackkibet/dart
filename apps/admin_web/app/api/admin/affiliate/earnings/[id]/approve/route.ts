import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { updateAffiliateCommission } from '@/lib/repositories/affiliateRepository';

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ id: string }> },
) {
  const result = await requireAdmin('affiliate:write');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  const body = await request.json().catch(() => ({}));
  return NextResponse.json(
    await updateAffiliateCommission({
      earningId: id,
      status: 'approved',
      actorUserId: result.admin.uid,
      reason: body.reason || '',
    }),
  );
}
