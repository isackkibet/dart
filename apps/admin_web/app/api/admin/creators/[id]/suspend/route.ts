import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { updateCreatorStatus } from '@/lib/repositories/creatorRepository';

export async function POST(request: NextRequest, context: { params: Promise<{ id: string }> }) {
  const result = await requireAdmin('creator:write');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  const body = await request.json().catch(() => ({}));
  return NextResponse.json(
    await updateCreatorStatus({ creatorId: id, status: 'suspended', actorUserId: result.admin.uid, reason: body.reason || '' }),
  );
}
