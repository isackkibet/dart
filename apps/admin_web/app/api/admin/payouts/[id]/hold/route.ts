import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { updatePayoutStatus } from '@/lib/repositories/financeRepository';

export async function POST(request: NextRequest, context: { params: Promise<{ id: string }> }) {
  const result = await requireAdmin('finance:approve');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  const body = await request.json().catch(() => ({}));
  await updatePayoutStatus({ payoutId: id, status: 'held', actorUserId: result.admin.uid, reason: body.reason || '' });
  return NextResponse.json({ ok: true });
}
