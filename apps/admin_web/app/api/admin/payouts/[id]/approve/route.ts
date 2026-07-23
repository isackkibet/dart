import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { approvePayout } from '@/lib/repositories/financeRepository';

export async function POST(request: NextRequest, context: { params: Promise<{ id: string }> }) {
  const result = await requireAdmin('finance:approve');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  const body = await request.json().catch(() => ({}));
  const data = await approvePayout({ payoutId: id, actorUserId: result.admin.uid, reason: body.reason || '' });
  return NextResponse.json(data);
}
