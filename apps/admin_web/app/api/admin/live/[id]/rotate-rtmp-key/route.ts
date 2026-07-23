import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { rotateRtmpKey } from '@/lib/repositories/liveRepository';

export async function POST(
  _: Request,
  context: { params: Promise<{ id: string }> },
) {
  const result = await requireAdmin('live:moderate');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  return NextResponse.json(
    await rotateRtmpKey({
      sessionId: id,
      actorUserId: result.admin.uid,
    }),
  );
}
