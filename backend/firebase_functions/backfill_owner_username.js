'use strict';
/**
 * Backfill ownerUsername on video docs that are missing it.
 *
 * Priority for display name:
 *   1. users/{uid}.userName  (e.g. "Alsha")
 *   2. users/{uid}.username  (lowercase variant)
 *   3. users/{uid}.firstName + ' ' + lastName
 *   4. creatorProfiles/{uid}.displayName
 *   5. Skip — leave ownerUsername empty rather than write a UID
 */
const admin = require('firebase-admin');
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'yohlab',
});
const db = admin.firestore();

function pickName(userData) {
  const u = userData || {};
  if (u.userName && u.userName.length < 30) return u.userName;
  if (u.username && u.username.length < 30) return u.username;
  const full = [u.firstName, u.lastName].filter(Boolean).join(' ').trim();
  if (full && full.length < 60) return full;
  return null;
}

async function run() {
  console.log('\nBackfilling ownerUsername on video docs...\n');

  // Pull all video docs (in pages of 200)
  const userCache = new Map();
  let updated = 0, skipped = 0, noUser = 0;
  let lastDoc = null;
  let page = 0;

  while (true) {
    let q = db.collection('videos').orderBy('__name__').limit(200);
    if (lastDoc) q = q.startAfter(lastDoc);
    const snap = await q.get();
    if (snap.empty) break;
    lastDoc = snap.docs[snap.docs.length - 1];
    page++;

    const batch = db.batch();
    let batchOps = 0;

    for (const doc of snap.docs) {
      const v = doc.data();

      // Already has a valid username (not a UID-length string)
      const existing = (v.ownerUsername || v.userName || '').trim();
      if (existing && existing.length < 30 && !/^[A-Za-z0-9]{20,}$/.test(existing)) {
        // Ensure ownerUsername field is set even if only userName was present
        if (!v.ownerUsername && v.userName) {
          batch.update(doc.ref, { ownerUsername: v.userName });
          batchOps++;
          updated++;
        } else {
          skipped++;
        }
        continue;
      }

      // Determine the owner uid
      const uid = (v.ownerId || v.userId || '').trim();
      if (!uid) { skipped++; continue; }

      // Look up user (cached)
      let name = null;
      if (userCache.has(uid)) {
        name = userCache.get(uid);
      } else {
        try {
          const userSnap = await db.collection('users').doc(uid).get();
          if (userSnap.exists) {
            name = pickName(userSnap.data());
          }
          if (!name) {
            const cpSnap = await db.collection('creatorProfiles').doc(uid).get();
            if (cpSnap.exists) name = cpSnap.data().displayName || null;
          }
        } catch (_) {}
        userCache.set(uid, name);
      }

      if (!name) { noUser++; continue; }

      batch.update(doc.ref, { ownerUsername: name });
      batchOps++;
      updated++;
      if (updated <= 20 || updated % 50 === 0) {
        console.log(`  ✓ ${doc.id.slice(0,14)}  →  @${name}`);
      }
    }

    if (batchOps > 0) await batch.commit();
    console.log(`Page ${page}: ${snap.size} docs processed (${batchOps} updated)`);
    if (snap.size < 200) break;
  }

  console.log('\n' + '─'.repeat(50));
  console.log(`Updated : ${updated}`);
  console.log(`Skipped : ${skipped}  (already had username)`);
  console.log(`No user : ${noUser}  (uid not found in users/creatorProfiles)`);
  console.log('\nownerUsername is now set on all reachable video docs.\n');
  process.exit(0);
}

run().catch(e => { console.error(e.message); process.exit(1); });
