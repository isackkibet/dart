import { NextRequest, NextResponse } from 'next/server';

const protectedRoutes = [
  '/dashboard',
  '/videos',
  '/creators',
  '/finance',
  '/live',
  '/multistream',
  '/advertiser',
  '/polls',
  '/ai-jobs',
  '/affiliate',
  '/chat',
  '/support',
  '/discovery',
  '/search',
  '/growth',
  '/notifications',
  '/moderation',
];

export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;
  const protectedRoute = protectedRoutes.some(
    (route) => pathname === route || pathname.startsWith(`${route}/`),
  );
  if (!protectedRoute) return NextResponse.next();

  const cookieName =
    process.env.ADMIN_SESSION_COOKIE_NAME || 'yohpal_admin_session';
  const session = request.cookies.get(cookieName)?.value;

  if (!session) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('next', pathname);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    '/dashboard/:path*',
    '/videos/:path*',
    '/creators/:path*',
    '/finance/:path*',
    '/live/:path*',
    '/multistream/:path*',
    '/advertiser/:path*',
    '/polls/:path*',
    '/ai-jobs/:path*',
    '/affiliate/:path*',
    '/chat/:path*',
    '/support/:path*',
    '/discovery/:path*',
    '/search/:path*',
    '/growth/:path*',
    '/notifications/:path*',
    '/moderation/:path*',
  ],
};
