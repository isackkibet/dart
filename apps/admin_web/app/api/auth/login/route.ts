import { NextRequest, NextResponse } from 'next/server';
import { auth, db, FieldValue } from '@/lib/firebaseAdmin';

export async function POST(request: NextRequest) {
  try {
    const { idToken } = await request.json();
    if (!idToken) {
      return NextResponse.json({ error: 'Missing ID token' }, { status: 400 });
    }

    const decoded = await auth.verifyIdToken(idToken);

    const adminDoc = await db.collection('admins').doc(decoded.uid).get();
    if (!adminDoc.exists) {
      return NextResponse.json(
        { error: 'Admin account not authorized' },
        { status: 403 },
      );
    }

    const expiresIn = 60 * 60 * 24 * 5 * 1000;
    const sessionCookie = await auth.createSessionCookie(idToken, { expiresIn });

    const response = NextResponse.json({ ok: true });
    response.cookies.set({
      name: process.env.ADMIN_SESSION_COOKIE_NAME || 'yohpal_admin_session',
      value: sessionCookie,
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: expiresIn / 1000,
      path: '/',
    });

    await db.collection('adminSessionLogs').add({
      adminUserId: decoded.uid,
      email: decoded.email || '',
      action: 'LOGIN',
      ip: request.headers.get('x-forwarded-for') || '',
      userAgent: request.headers.get('user-agent') || '',
      createdAt: FieldValue.serverTimestamp(),
    });

    return response;
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Login failed';
    return NextResponse.json({ error: message }, { status: 401 });
  }
}
