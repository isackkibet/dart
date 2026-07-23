import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { NextResponse } from 'next/server';

export type AdminRole =
  | 'owner'
  | 'moderator'
  | 'finance'
  | 'advertiser'
  | 'polls'
  | 'support'
  | 'viewer'
  | 'creator_manager'
  | 'live_moderator'
  | 'affiliate_manager';

export type AdminUser = { uid: string; email?: string; role: AdminRole; permissions: string[] };

export const rolePermissions: Record<AdminRole, string[]> = {
  owner: ['*'],
  moderator: ['dashboard:read', 'moderation:read', 'moderation:write', 'video:read', 'video:write'],
  creator_manager: ['dashboard:read', 'creator:read', 'creator:write', 'video:read', 'video:write'],
  finance: ['dashboard:read', 'finance:read', 'finance:approve', 'wallet:read'],
  advertiser: ['dashboard:read', 'ads:read', 'ads:write'],
  polls: ['dashboard:read', 'polls:read', 'polls:write'],
  support: ['dashboard:read', 'moderation:read'],
  live_moderator: ['dashboard:read', 'live:read', 'live:moderate', 'moderation:read', 'moderation:write'],
  affiliate_manager: ['dashboard:read', 'affiliate:read', 'affiliate:write'],
  viewer: ['dashboard:read'],
};

export function hasPermission(u: AdminUser, p: string) {
  return u.permissions.includes('*') || u.permissions.includes(p);
}

export async function getCurrentAdmin(): Promise<AdminUser | null> {
  const c = await cookies();
  const token = c.get(process.env.ADMIN_SESSION_COOKIE_NAME || 'yohpal_admin_session')?.value;
  if (!token) return null;
  try {
    const { auth, db } = await import('./firebaseAdmin');
    const decoded = await auth.verifySessionCookie(token, true);
    const doc = await db.collection('admins').doc(decoded.uid).get();
    if (!doc.exists) return null;
    const d = doc.data() || {};
    const role = (d.role || 'viewer') as AdminRole;
    return { uid: decoded.uid, email: decoded.email, role, permissions: d.permissions || rolePermissions[role] || [] };
  } catch {
    return null;
  }
}

// For server-component pages: redirects to /login if unauthenticated or missing permission.
export async function requirePageAdmin(permission?: string): Promise<AdminUser> {
  const admin = await getCurrentAdmin();
  if (!admin) redirect('/login');
  if (permission && !hasPermission(admin, permission)) redirect('/403');
  return admin;
}

// For API routes: returns structured result so the route can return the error response.
type AuthResult = { ok: true; admin: AdminUser } | { ok: false; response: NextResponse };

export async function requireAdmin(permission?: string): Promise<AuthResult> {
  const admin = await getCurrentAdmin();
  if (!admin) return { ok: false, response: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }) };
  if (permission && !hasPermission(admin, permission)) {
    return { ok: false, response: NextResponse.json({ error: 'Forbidden' }, { status: 403 }) };
  }
  return { ok: true, admin };
}
