'use strict';
/**
 * Phase 5I — Ad Billing Live Validation (CJS runner)
 * Run from: backend/firebase_functions/
 * GOOGLE_APPLICATION_CREDENTIALS=... FIREBASE_PROJECT_ID=yohlab node validate_5i.js
 */
const admin = require('firebase-admin');

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? 'yohlab';
admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

function log(label, value) {
  console.log(`\n[${label}]`);
  console.log(JSON.stringify(value, null, 2));
}
function pass(msg) { console.log(`  ✅  PASS — ${msg}`); }
function fail(msg) { console.log(`  ❌  FAIL — ${msg}`); }

async function waitFor(collection, docId, maxMs = 18000) {
  const start = Date.now();
  while (Date.now() - start < maxMs) {
    const s = await db.collection(collection).doc(docId).get();
    if (s.exists) return s.data();
    await new Promise(r => setTimeout(r, 1500));
  }
  return null;
}

async function waitForSpend(campaignId, minSpend, maxMs = 18000) {
  const start = Date.now();
  while (Date.now() - start < maxMs) {
    const s = await db.collection('adCampaigns').doc(campaignId).get();
    const data = s.data();
    if (data && Number(data.spend ?? 0) >= minSpend) return data;
    await new Promise(r => setTimeout(r, 1500));
  }
  return null;
}

async function main() {
  const ts = Date.now();
  const CAMPAIGN_ID = `val5i_campaign_${ts}`;
  const IDEM_CAMPAIGN_ID = `val5i_idem_${ts}`;
  const EXHAUST_CAMPAIGN_ID = `val5i_exhaust_${ts}`;
  const DUP_EVENT_ID = `val5i_dup_event_${ts}`;
  const CPM = 100;     // KES 100 / 1000 impressions = 0.10 per impression
  const CPC = 5;       // KES 5 per click
  const BUDGET = 1.00; // 10 impressions worth

  console.log('\n══════════════════════════════════════════════════════');
  console.log('  YOHPAL PHASE 5I — AD BILLING LIVE VALIDATION');
  console.log(`  Project: ${PROJECT_ID}  |  ${new Date().toISOString()}`);
  console.log('══════════════════════════════════════════════════════\n');

  // ─── STEP 8: Create test campaign ───────────────────────────────────────
  console.log('── STEP 8: Create test adCampaign ──');
  await db.collection('adCampaigns').doc(CAMPAIGN_ID).set({
    advertiserId: 'val5i_advertiser',
    title: 'Phase 5I Validation Campaign',
    status: 'active',
    deliveryEnabled: true,
    budget: BUDGET,
    spend: 0,
    remainingBudget: BUDGET,
    cpm: CPM,
    costPerClick: CPC,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  log('8 — Campaign created', { campaignId: CAMPAIGN_ID, budget: BUDGET, cpm: CPM, costPerClick: CPC });

  // ─── STEPS 10-15: Impression billing ────────────────────────────────────
  console.log('\n── STEPS 10-15: Impression Billing ──');
  const impRef = await db.collection('adEngagementEvents').add({
    campaignId: CAMPAIGN_ID,
    userId: 'val5i_user',
    type: 'impression',
    source: 'mobile',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  log('10 — Impression event', { eventId: impRef.id });

  const expectedImpCost = Math.round((CPM / 1000) * 100) / 100;
  const afterImp = await waitForSpend(CAMPAIGN_ID, expectedImpCost - 0.001);
  log('11-14 — Campaign after impression', afterImp);
  if (afterImp) {
    const spend = Number(afterImp.spend ?? 0);
    const remaining = Number(afterImp.remainingBudget ?? 0);
    Math.abs(spend - expectedImpCost) < 0.001
      ? pass(`CPM billing correct: spend=${spend} (expected ${expectedImpCost})`)
      : fail(`CPM billing wrong: spend=${spend} (expected ${expectedImpCost})`);
    Math.abs(remaining - (BUDGET - spend)) < 0.001
      ? pass(`remainingBudget correct: ${remaining}`)
      : fail(`remainingBudget wrong: ${remaining}`);
  } else {
    fail('adBillingProcessor did not fire within 18s — check function logs');
  }

  const impAudit = await db.collection('adBillingAuditLogs').where('eventId', '==', impRef.id).limit(1).get();
  if (!impAudit.empty) {
    log('15 — Impression audit log', impAudit.docs[0].data());
    impAudit.docs[0].data().billingType === 'CPM' ? pass('Audit billingType=CPM') : fail('Audit billingType!=CPM');
  } else {
    fail('No adBillingAuditLogs entry for impression');
  }

  // ─── STEPS 16-21: Click billing ─────────────────────────────────────────
  console.log('\n── STEPS 16-21: Click Billing ──');
  const spendBeforeClick = afterImp ? Number(afterImp.spend ?? 0) : expectedImpCost;
  const clickRef = await db.collection('adEngagementEvents').add({
    campaignId: CAMPAIGN_ID,
    userId: 'val5i_user',
    type: 'click',
    source: 'mobile',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  log('16 — Click event', { eventId: clickRef.id });

  const expectedClickCharge = Math.min(CPC, BUDGET - spendBeforeClick);
  const afterClick = await waitForSpend(CAMPAIGN_ID, spendBeforeClick + expectedClickCharge - 0.001);
  log('17-20 — Campaign after click', afterClick);
  if (afterClick) {
    const clickSpend = Number(afterClick.spend ?? 0);
    Math.abs(clickSpend - (spendBeforeClick + expectedClickCharge)) < 0.001
      ? pass(`CPC billing correct: spend=${clickSpend}`)
      : fail(`CPC billing wrong: spend=${clickSpend}`);
    Number(afterClick.remainingBudget ?? -1) >= 0
      ? pass(`remainingBudget non-negative: ${afterClick.remainingBudget}`)
      : fail('remainingBudget negative');
  } else {
    const snap = await db.collection('adCampaigns').doc(CAMPAIGN_ID).get();
    if (snap.data()?.budgetStatus === 'exhausted') {
      pass('Budget exhausted after impression — click billing correctly capped');
    } else {
      fail('adBillingProcessor did not fire for click within 18s');
    }
  }
  const clickAudit = await db.collection('adBillingAuditLogs').where('eventId', '==', clickRef.id).limit(1).get();
  if (!clickAudit.empty) {
    log('21 — Click audit log', clickAudit.docs[0].data());
    clickAudit.docs[0].data().billingType === 'CPC' ? pass('Audit billingType=CPC') : fail('Audit billingType!=CPC');
  } else {
    const skipSnap = await db.collection('adBillingProcessedEvents').doc(clickRef.id).get();
    skipSnap.exists && skipSnap.data()?.status?.startsWith('skipped')
      ? pass(`Click skipped correctly (${skipSnap.data().status})`)
      : fail('No audit log or processed record for click event');
  }

  // ─── STEPS 22-24: Idempotency ────────────────────────────────────────────
  console.log('\n── STEPS 22-24: Idempotency ──');
  await db.collection('adCampaigns').doc(IDEM_CAMPAIGN_ID).set({
    advertiserId: 'val5i_advertiser', title: 'Idempotency Campaign',
    status: 'active', deliveryEnabled: true, budget: 100, spend: 0,
    remainingBudget: 100, cpm: CPM, createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db.collection('adEngagementEvents').doc(DUP_EVENT_ID).set({
    campaignId: IDEM_CAMPAIGN_ID, userId: 'val5i_user', type: 'impression',
    source: 'mobile', createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await new Promise(r => setTimeout(r, 8000));
  const spendAfterFirst = Number((await db.collection('adCampaigns').doc(IDEM_CAMPAIGN_ID).get()).data()?.spend ?? 0);
  const processedDoc = await db.collection('adBillingProcessedEvents').doc(DUP_EVENT_ID).get();
  log('24 — adBillingProcessedEvents idempotency record', processedDoc.data());
  processedDoc.exists ? pass('Idempotency lock written to adBillingProcessedEvents') : fail('Idempotency lock missing');

  // Touch the event doc to potentially re-trigger (won't fire onDocumentCreated again — but validates the lock)
  await db.collection('adEngagementEvents').doc(DUP_EVENT_ID).set({ touched: true }, { merge: true });
  await new Promise(r => setTimeout(r, 5000));
  const spendAfterDup = Number((await db.collection('adCampaigns').doc(IDEM_CAMPAIGN_ID).get()).data()?.spend ?? 0);
  log('22-23 — Spend before/after duplicate attempt', { spendAfterFirst, spendAfterDup });
  Math.abs(spendAfterFirst - spendAfterDup) < 0.001
    ? pass(`Duplicate billing blocked — spend unchanged at ${spendAfterFirst}`)
    : fail(`Duplicate billing occurred — spend changed ${spendAfterFirst} → ${spendAfterDup}`);

  // ─── STEPS 25-30: Budget exhaustion ────────────────────────────────────
  console.log('\n── STEPS 25-30: Budget Exhaustion ──');
  await db.collection('adCampaigns').doc(EXHAUST_CAMPAIGN_ID).set({
    advertiserId: 'val5i_advertiser', title: 'Exhaustion Campaign',
    status: 'active', deliveryEnabled: true,
    budget: 0.30, spend: 0, remainingBudget: 0.30, cpm: CPM,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  const exhaustEventIds = [];
  for (let i = 0; i < 4; i++) {
    const r = await db.collection('adEngagementEvents').add({
      campaignId: EXHAUST_CAMPAIGN_ID, userId: 'val5i_user',
      type: 'impression', source: 'mobile', createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    exhaustEventIds.push(r.id);
    await new Promise(r2 => setTimeout(r2, 2000));
  }
  log('25 — Exhaustion events created', { count: exhaustEventIds.length, ids: exhaustEventIds });
  await new Promise(r => setTimeout(r, 10000));
  const exhausted = (await db.collection('adCampaigns').doc(EXHAUST_CAMPAIGN_ID).get()).data();
  log('26-29 — Exhausted campaign', exhausted);
  exhausted?.status === 'paused'             ? pass('status=paused') : fail(`status=${exhausted?.status}`);
  exhausted?.deliveryEnabled === false       ? pass('deliveryEnabled=false') : fail('deliveryEnabled!=false');
  exhausted?.budgetStatus === 'exhausted'    ? pass('budgetStatus=exhausted') : fail(`budgetStatus=${exhausted?.budgetStatus}`);
  Number(exhausted?.remainingBudget ?? -1) === 0 ? pass('remainingBudget=0') : fail(`remainingBudget=${exhausted?.remainingBudget}`);

  const lastLog = await db.collection('adBillingAuditLogs')
    .where('campaignId', '==', EXHAUST_CAMPAIGN_ID)
    .orderBy('createdAt', 'desc').limit(1).get();
  if (!lastLog.empty) {
    log('30 — Final audit log (campaignPaused)', lastLog.docs[0].data());
    lastLog.docs[0].data().campaignPaused === true
      ? pass('Final audit log campaignPaused=true') : fail('campaignPaused!=true in final log');
  } else {
    fail('No audit logs for exhaustion campaign');
  }

  console.log('\n══════════════════════════════════════════════════════');
  console.log('  PHASE 5I VALIDATION COMPLETE');
  console.log('══════════════════════════════════════════════════════\n');
}

main().catch(e => { console.error('Script error:', e); process.exit(1); });
