import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { updatePollVoteStatus } from '@/lib/repositories/pollsRepository';

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ id: string }> },
) {
  const result = await requireAdmin('polls:write');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  const body = await request.json().catch(() => ({}));
  return NextResponse.json(
    await updatePollVoteStatus({
      voteId: id,
      status: 'approved',
      actorUserId: result.admin.uid,
      reason: body.reason || '',
    }),
  );
}
