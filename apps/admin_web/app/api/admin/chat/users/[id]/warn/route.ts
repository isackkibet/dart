import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { warnChatUser } from '@/lib/repositories/chatAdminRepository';

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ id: string }> },
) {
  const result = await requireAdmin('moderation:write');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  const body = await request.json().catch(() => ({}));
  return NextResponse.json(
    await warnChatUser({
      userId: id,
      actorUserId: result.admin.uid,
      reason: body.reason || '',
    }),
  );
}
