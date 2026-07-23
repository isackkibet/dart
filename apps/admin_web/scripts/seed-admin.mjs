/**
 * seed-admin.mjs — one-time script to create a YohPal admin login
 *
 * Usage:
 *   node scripts/seed-admin.mjs <email> <password> <role>
 *
 * Examples:
 *   node scripts/seed-admin.mjs admin@yohpal.com secret123 owner
 *   node scripts/seed-admin.mjs finance@yohpal.com secret123 finance
 *
 * Reads Firebase credentials from .env.local automatically.
 * Safe to run multiple times — updates the Firestore doc if the user already exists.
 * DELETE this script from the repo after first use.
 */

import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

// ── Read .env.local ───────────────────────────────────────────────────────────
const __dirname = dirname(fileURLToPath(import.meta.url));
const envPath = resolve(__dirname, '..', '.env.local');

let env = {};
try {
  const raw = readFileSync(envPath, 'utf8');
  for (const line of raw.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const k = trimmed.slice(0, eq).trim();
    let v = trimmed.slice(eq + 1).trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      v = v.slice(1, -1);
    }
    env[k] = v.replace(/\\n/g, '\n');
  }
  console.log(`✓ Loaded .env.local from ${envPath}`);
} catch {
  console.warn(`⚠ Could not read .env.local — falling back to process.env`);
  env = process.env;
}

// ── Validate args ─────────────────────────────────────────────────────────────
const VALID_ROLES = [
  'owner', 'moderator', 'creator_manager', 'finance',
  'advertiser', 'polls', 'support', 'live_moderator',
  'affiliate_manager', 'viewer',
];

const ROLE_PERMISSIONS = {
  owner:             ['*'],
  moderator:         ['dashboard:read', 'moderation:read', 'moderation:write', 'video:read', 'video:write'],
  creator_manager:   ['dashboard:read', 'creator:read', 'creator:write', 'video:read', 'video:write'],
  finance:           ['dashboard:read', 'finance:read', 'finance:approve', 'wallet:read'],
  advertiser:        ['dashboard:read', 'ads:read', 'ads:write'],
  polls:             ['dashboard:read', 'polls:read', 'polls:write'],
  support:           ['dashboard:read', 'moderation:read'],
  live_moderator:    ['dashboard:read', 'live:read', 'live:moderate', 'moderation:read', 'moderation:write'],
  affiliate_manager: ['dashboard:read', 'affiliate:read', 'affiliate:write'],
  viewer:            ['dashboard:read'],
};

const [,, email, password, role = 'owner'] = process.argv;

if (!email || !password) {
  console.error('\nUsage: node scripts/seed-admin.mjs <email> <password> <role>\n');
  console.error('Roles:', VALID_ROLES.join(', '));
  process.exit(1);
}
if (!VALID_ROLES.includes(role)) {
  console.error(`\nInvalid role "${role}". Valid roles: ${VALID_ROLES.join(', ')}\n`);
  process.exit(1);
}

// ── Init Firebase Admin ───────────────────────────────────────────────────────
if (!getApps().length) {
  const projectId    = env.FIREBASE_PROJECT_ID;
  const clientEmail  = env.FIREBASE_CLIENT_EMAIL;
  const privateKey   = env.FIREBASE_PRIVATE_KEY;

  if (!projectId || !clientEmail || !privateKey) {
    console.error('\n✗ Missing Firebase credentials in .env.local:');
    if (!projectId)   console.error('  FIREBASE_PROJECT_ID');
    if (!clientEmail) console.error('  FIREBASE_CLIENT_EMAIL');
    if (!privateKey)  console.error('  FIREBASE_PRIVATE_KEY');
    process.exit(1);
  }

  initializeApp({ credential: cert({ projectId, clientEmail, privateKey }) });
  console.log(`✓ Firebase Admin initialised (project: ${projectId})`);
}

const authClient = getAuth();
const db = getFirestore();

// ── Create or look up the Firebase Auth user ──────────────────────────────────
let uid;
try {
  const existing = await authClient.getUserByEmail(email);
  uid = existing.uid;
  // Update password in case it changed
  await authClient.updateUser(uid, { password });
  console.log(`✓ Firebase Auth user already exists — uid: ${uid}`);
} catch (err) {
  if (err.code === 'auth/user-not-found') {
    const created = await authClient.createUser({ email, password });
    uid = created.uid;
    console.log(`✓ Firebase Auth user created — uid: ${uid}`);
  } else {
    throw err;
  }
}

// ── Write / update the Firestore admins doc ───────────────────────────────────
const adminRef = db.collection('admins').doc(uid);
await adminRef.set({
  email,
  role,
  permissions: ROLE_PERMISSIONS[role],
  createdAt: FieldValue.serverTimestamp(),
  updatedAt: FieldValue.serverTimestamp(),
}, { merge: true });

console.log(`\n✅ Admin account ready`);
console.log(`   Email      : ${email}`);
console.log(`   UID        : ${uid}`);
console.log(`   Role       : ${role}`);
console.log(`   Permissions: ${ROLE_PERMISSIONS[role].join(', ')}`);
console.log(`\n   Login at   : http://localhost:3000/login`);
console.log(`\n⚠  Delete this script after use: rm scripts/seed-admin.mjs\n`);
