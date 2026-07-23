import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { updateChargeback } from '@/lib/repositories/disputeRepository';

export async function POST(request: NextRequest, context: { params: Promise<{ id: string }> }) {
  const result = await requireAdmin('finance:approve');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  const body = await request.json().catch(() => ({}));
  return NextResponse.json(
    await updateChargeback({ id, status: 'rejected', actorUserId: result.admin.uid, reason: body.reason || '' }),
  );
}
