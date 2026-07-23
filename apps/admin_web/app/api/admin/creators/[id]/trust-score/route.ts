import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { updateCreatorTrustScore } from '@/lib/repositories/creatorRepository';

export async function POST(request: NextRequest, context: { params: Promise<{ id: string }> }) {
  const result = await requireAdmin('creator:write');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  const body = await request.json().catch(() => ({}));
  return NextResponse.json(
    await updateCreatorTrustScore({ creatorId: id, trustScore: Number(body.trustScore || 0), actorUserId: result.admin.uid, reason: body.reason || '' }),
  );
}
