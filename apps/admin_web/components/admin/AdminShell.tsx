'use client';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import type { AdminUser } from '@/lib/auth';

const nav = [
  { label: 'Dashboard',     href: '/dashboard',       permission: 'dashboard:read' },
  { label: 'Videos',        href: '/videos',          permission: 'video:read' },
  { label: 'Broken Videos', href: '/videos/broken',   permission: 'video:read' },
  { label: 'Creators',      href: '/creators',        permission: 'creator:read' },
  { label: 'Finance',          href: '/finance',                    permission: 'finance:read' },
  { label: 'Payouts',          href: '/finance/payouts',            permission: 'finance:approve' },
  { label: 'Reconciliation',   href: '/finance/reconciliation',     permission: 'finance:approve' },
  { label: 'Risk Reviews',     href: '/finance/risk-reviews',       permission: 'finance:approve' },
  { label: 'Live',           href: '/live',            permission: 'live:read' },
  { label: 'Live Reports',   href: '/live/reports',    permission: 'live:moderate' },
  { label: 'Live Tips',      href: '/live/tips',       permission: 'finance:read' },
  { label: 'Multistream',    href: '/multistream',     permission: 'live:read' },
  { label: 'Advertiser',       href: '/advertiser',              permission: 'ads:read' },
  { label: 'Ad Campaigns',     href: '/advertiser/campaigns',    permission: 'ads:read' },
  { label: 'Ad Revenue',       href: '/advertiser/revenue',      permission: 'ads:read' },
  { label: 'Polls',            href: '/polls',                   permission: 'polls:read' },
  { label: 'Poll Management',  href: '/polls/manage',            permission: 'polls:read' },
  { label: 'Poll Fraud',       href: '/polls/fraud',             permission: 'polls:write' },
  { label: 'AI Jobs',          href: '/ai-jobs',                 permission: 'video:write' },
  { label: 'Affiliate',        href: '/affiliate',               permission: 'affiliate:read' },
  { label: 'Affiliate Earnings', href: '/affiliate/earnings',    permission: 'affiliate:write' },
  { label: 'Chat Moderation',   href: '/chat/moderation',         permission: 'moderation:write' },
  { label: 'Support',           href: '/support',                 permission: 'dashboard:read' },
  { label: 'Featured Content',  href: '/discovery/featured',      permission: 'video:write' },
  { label: 'Trending Topics',   href: '/discovery/trending',      permission: 'video:write' },
  { label: 'Search',            href: '/search',                  permission: 'dashboard:read' },
  { label: 'Growth',            href: '/growth',                  permission: 'dashboard:read' },
  { label: 'Notifications',     href: '/notifications',           permission: 'dashboard:read' },
  { label: 'Chargebacks',      href: '/finance/chargebacks',    permission: 'finance:approve' },
  { label: 'Sponsored Polls',  href: '/polls/sponsored',        permission: 'polls:write' },
  { label: 'Referrals',        href: '/affiliate/referrals',    permission: 'affiliate:read' },
  { label: 'Contacts',         href: '/growth/contacts',        permission: 'dashboard:read' },
  { label: 'Blocked Search',   href: '/search/blocked',         permission: 'dashboard:read' },
  { label: 'Moderation',        href: '/moderation',              permission: 'moderation:read' },
];

function can(admin: AdminUser, permission: string) {
  return admin.permissions.includes('*') || admin.permissions.includes(permission);
}

export function AdminShell({
  children,
  admin,
}: {
  children: React.ReactNode;
  admin: AdminUser;
}) {
  const pathname = usePathname();
  const router = useRouter();

  async function logout() {
    await fetch('/api/auth/logout', { method: 'POST' });
    router.replace('/login');
  }

  const visibleNav = nav.filter((item) => can(admin, item.permission));

  return (
    <div style={{ minHeight: '100vh', display: 'flex' }}>
      <aside
        style={{
          width: 280,
          padding: 24,
          background: 'rgba(16,21,39,.92)',
          borderRight: '1px solid var(--border)',
          height: '100vh',
          position: 'sticky',
          top: 0,
          overflowY: 'auto',
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        <h2>YohPal Admin</h2>
        <p style={{ color: 'var(--muted)', fontSize: 13 }}>
          {admin.email || admin.uid}
          <br />
          Role: {admin.role}
        </p>
        <nav style={{ display: 'grid', gap: 10, marginTop: 28 }}>
          {visibleNav.map((item) => {
            const active =
              pathname === item.href || pathname.startsWith(`${item.href}/`);
            return (
              <Link
                key={item.href}
                href={item.href}
                style={{
                  padding: 12,
                  borderRadius: 16,
                  border: '1px solid rgba(0,217,255,.12)',
                  background: active ? 'rgba(0,217,255,.16)' : 'transparent',
                  color: active ? 'var(--blue)' : 'var(--text)',
                  textDecoration: 'none',
                }}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>
        <button
          onClick={logout}
          className="btn"
          style={{ width: '100%', marginTop: 'auto' }}
        >
          Logout
        </button>
      </aside>
      <main style={{ flex: 1, padding: 32 }}>{children}</main>
    </div>
  );
}
