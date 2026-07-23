import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/auth';
import { createBroadcastNotification } from '@/lib/repositories/notificationRepository';

export async function POST(request: NextRequest) {
  const result = await requireAdmin('dashboard:read');
  if (!result.ok) return result.response;
  const body = await request.json();
  return NextResponse.json(
    await createBroadcastNotification({
      title: body.title,
      message: body.message,
      audience: body.audience || 'all',
      actorUserId: result.admin.uid,
    }),
  );
}
