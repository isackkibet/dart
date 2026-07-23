import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { resolveLiveReport } from '@/lib/repositories/liveReportRepository';

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ id: string }> },
) {
  const result = await requireAdmin('live:moderate');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  const body = await request.json().catch(() => ({}));
  return NextResponse.json(
    await resolveLiveReport({
      reportId: id,
      action: 'approved',
      actorUserId: result.admin.uid,
      reason: body.reason || '',
    }),
  );
}
