import { NextRequest, NextResponse } from 'next/server';
import { resolveModerationReport } from '@/lib/repositories/moderationRepository';
import { requireAdmin } from '@/lib/auth';

export async function POST(_: NextRequest, context: { params: Promise<{ id: string }> }) {
  const result = await requireAdmin('moderation:write');
  if (!result.ok) return result.response;
  const { id } = await context.params;
  await resolveModerationReport({ reportId: id, action: 'reject', actorUserId: result.admin.uid });
  return NextResponse.json({ ok: true, reportId: id, action: 'reject' });
}
