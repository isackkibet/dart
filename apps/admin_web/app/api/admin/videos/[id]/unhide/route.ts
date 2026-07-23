import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { updateVideoVisibility } from '@/lib/repositories/videoRepository';

export async function POST(request: NextRequest, context: { params: Promise<{ id: string }> }) {
  const result = await requireAdmin('video:write');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  const body = await request.json().catch(() => ({}));
  return NextResponse.json(
    await updateVideoVisibility({ videoId: id, visibility: 'public', actorUserId: result.admin.uid, reason: body.reason || '' }),
  );
}
