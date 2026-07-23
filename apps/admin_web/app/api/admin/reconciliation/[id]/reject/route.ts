import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { resolveReconciliation } from '@/lib/repositories/reconciliationRepository';

export async function POST(request: NextRequest, context: { params: Promise<{ id: string }> }) {
  const result = await requireAdmin('finance:approve');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  const body = await request.json().catch(() => ({}));
  return NextResponse.json(
    await resolveReconciliation({ id, action: 'rejected', actorUserId: result.admin.uid, reason: body.reason || '' }),
  );
}
