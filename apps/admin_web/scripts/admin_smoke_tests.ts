// Smoke tests: verifies all routes respond correctly via HTTP
// Requires the dev server to be running at http://localhost:3000

import { execSync } from 'child_process';

const BASE = process.env.SMOKE_BASE_URL || 'http://localhost:3000';

// Get dev session cookie
let cookieHeader = '';
try {
  const res = execSync(`curl -s -c /tmp/smoke_cookie.txt -X POST ${BASE}/api/auth/dev-login`, { encoding: 'utf8' });
  const parsed = JSON.parse(res);
  if (!parsed.ok) throw new Error('dev-login failed');
  cookieHeader = '-b /tmp/smoke_cookie.txt';
  console.log('✓ Dev login successful');
} catch (e) {
  console.error('✗ Could not obtain dev session:', e);
  process.exit(1);
}

type TestResult = { route: string; expected: number; actual: number; pass: boolean };
const results: TestResult[] = [];

function test(route: string, expectedStatus: number, method = 'GET', body?: string) {
  try {
    const bodyFlag = body ? `-d '${body}' -H 'Content-Type: application/json'` : '';
    const cmd = `curl -s -o /dev/null -w "%{http_code}" -X ${method} ${cookieHeader} ${bodyFlag} "${BASE}${route}" --max-time 5`;
    const actual = parseInt(execSync(cmd, { encoding: 'utf8' }).trim(), 10);
    const pass = actual === expectedStatus;
    results.push({ route, expected: expectedStatus, actual, pass });
    console.log(`${pass ? '✓' : '✗'} [${actual}] ${method} ${route}`);
  } catch {
    results.push({ route, expected: expectedStatus, actual: 0, pass: false });
    console.log(`✗ [ERR] ${method} ${route}`);
  }
}

console.log('\n=== ADMIN PAGES SMOKE TEST ===');
const pages = [
  '/dashboard','/videos','/videos/broken','/videos/analytics',
  '/creators','/finance','/finance/payouts','/finance/reconciliation',
  '/finance/risk-reviews','/finance/chargebacks',
  '/live','/live/reports','/live/tips','/multistream',
  '/advertiser','/advertiser/campaigns','/advertiser/revenue',
  '/polls','/polls/manage','/polls/fraud','/polls/sponsored',
  '/ai-jobs','/affiliate','/affiliate/earnings','/affiliate/referrals',
  '/chat/moderation','/support','/discovery/featured','/discovery/trending',
  '/search','/search/blocked','/growth','/growth/contacts',
  '/notifications','/moderation','/403',
];
pages.forEach(p => test(p, 200));

console.log('\n=== API ROUTES AUTH GUARD TEST (no cookie) ===');
const apiRoutes = [
  '/api/admin/payouts/test-id/approve','/api/admin/payouts/test-id/hold','/api/admin/payouts/test-id/reject',
  '/api/admin/moderation/test-id/approve','/api/admin/moderation/test-id/hide','/api/admin/moderation/test-id/reject',
  '/api/admin/videos/test-id/hide','/api/admin/videos/test-id/unhide','/api/admin/videos/test-id/delete','/api/admin/videos/test-id/restrict',
  '/api/admin/creators/test-id/ban','/api/admin/creators/test-id/suspend',
  '/api/admin/chargebacks/test-id/approve','/api/admin/chargebacks/test-id/reject','/api/admin/chargebacks/test-id/escalate',
];
// Without cookie should get 401
apiRoutes.forEach(r => {
  try {
    const cmd = `curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE}${r}" -H 'Content-Type: application/json' -d '{}' --max-time 5`;
    const actual = parseInt(execSync(cmd, { encoding: 'utf8' }).trim(), 10);
    const pass = actual === 401;
    results.push({ route: r + ' (no-auth)', expected: 401, actual, pass });
    console.log(`${pass ? '✓' : '✗'} [${actual}] POST ${r} (no-auth → expect 401)`);
  } catch {
    results.push({ route: r, expected: 401, actual: 0, pass: false });
  }
});

console.log('\n=== /403 PAGE TEST ===');
test('/403', 200);

console.log('\n=== SUMMARY ===');
const passed = results.filter(r => r.pass).length;
const failed = results.filter(r => !r.pass);
console.log(`Passed: ${passed}/${results.length}`);
if (failed.length) {
  console.log('Failed:');
  failed.forEach(f => console.log(`  ✗ ${f.route} expected=${f.expected} actual=${f.actual}`));
}
console.log(passed === results.length ? '\n✓ All smoke tests passed' : '\n⚠ Some tests failed');
process.exit(failed.length > 0 ? 1 : 0);
