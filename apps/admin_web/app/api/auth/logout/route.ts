import { NextRequest, NextResponse } from 'next/server';
import { getCurrentAdmin } from '@/lib/auth';
import { db, FieldValue } from '@/lib/firebaseAdmin';

export async function POST(request: NextRequest) {
  const admin = await getCurrentAdmin();
  if (admin) {
    await db.collection('adminSessionLogs').add({
      adminUserId: admin.uid,
      email: admin.email || '',
      action: 'LOGOUT',
      ip: request.headers.get('x-forwarded-for') || '',
      userAgent: request.headers.get('user-agent') || '',
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  const response = NextResponse.json({ ok: true });
  response.cookies.set({
    name: process.env.ADMIN_SESSION_COOKIE_NAME || 'yohpal_admin_session',
    value: '',
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 0,
    path: '/',
  });
  return response;
}
