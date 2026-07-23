/**
 * Phase 5I — Ad Billing Validation Script
 *
 * Run AFTER adBillingProcessor + campaignBudgetStatusUpdater are deployed.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json \
 *   FIREBASE_PROJECT_ID=yohpal-a3125 \
 *   npx ts-node backend/scripts/validate_ad_billing_5i.ts
 *
 * The script drives the full Phase 5I checklist in order and prints
 * a structured report to stdout.
 */

import * as admin from 'firebase-admin';

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? 'yohpal-a3125';

admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

// ── helpers ─────────────────────────────────────────────────────────────────

function log(label: string, value: unknown) {
  console.log(`\n[${label}]`);
  console.log(JSON.stringify(value, null, 2));
}

function pass(msg: string) {
  console.log(`  ✅  PASS — ${msg}`);
}

function fail(msg: string) {
  console.log(`  ❌  FAIL — ${msg}`);
}

async function waitForProcessing(
  collection: string,
  docId: string,
  maxWaitMs = 15_000,
): Promise<admin.firestore.DocumentData | null> {
  const start = Date.now();
  while (Date.now() - start < maxWaitMs) {
    const snap = await db.collection(collection).doc(docId).get();
    if (snap.exists) return snap.data() ?? null;
    await new Promise((r) => setTimeout(r, 1_000));
  }
  return null;
}

async function waitForCampaignSpend(
  campaignId: string,
  expectedSpend: number,
  maxWaitMs = 15_000,
): Promise<admin.firestore.DocumentData | null> {
  const start = Date.now();
  while (Date.now() - start < maxWaitMs) {
    const snap = await db.collection('adCampaigns').doc(campaignId).get();
    const data = snap.data();
    if (data && Number(data.spend ?? 0) >= expectedSpend) return data;
    await new Promise((r) => setTimeout(r, 1_000));
  }
  return null;
}

// ── main ─────────────────────────────────────────────────────────────────────

async function main() {
  const CAMPAIGN_ID = `test_campaign_5i_${Date.now()}`;
  const DUPLICATE_EVENT_ID = `test_dup_event_${Date.now()}`;
  const CPM = 100;       // KES 100 per 1000 impressions → 0.10 per impression
  const CPC = 5;         // KES 5 per click
  const BUDGET = 0.30;   // Small budget: 3 impressions worth (KES 0.10 each) or fewer clicks

  console.log('\n═══════════════════════════════════════════════════════════');
  console.log('  YOHPAL PHASE 5I — AD BILLING VALIDATION REPORT');
  console.log(`  Project: ${PROJECT_ID}  |  Date: ${new Date().toISOString()}`);
  console.log('═══════════════════════════════════════════════════════════\n');

  // ── STEP 8: Create test adCampaign ──────────────────────────────────────
  console.log('── STEP 8: Create test adCampaign ──');
  await db.collection('adCampaigns').doc(CAMPAIGN_ID).set({
    advertiserId: 'test_advertiser_5i',
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
  log('8 — Test campaign created', { campaignId: CAMPAIGN_ID, budget: BUDGET, cpm: CPM, costPerClick: CPC });

  // ── STEP 10-15: Impression billing ──────────────────────────────────────
  console.log('\n── STEPS 10-15: Impression Billing ──');
  const impressionRef = await db.collection('adEngagementEvents').add({
    campaignId: CAMPAIGN_ID,
    userId: 'test_user_5i',
    type: 'impression',
    source: 'mobile',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  const impressionEventId = impressionRef.id;
  log('10 — Impression event created', { eventId: impressionEventId });

  const campaignAfterImpression = await waitForCampaignSpend(CAMPAIGN_ID, 0.09);
  log('11/12/13/14 — Campaign after impression', campaignAfterImpression);

  const expectedImpressionCost = Math.round((CPM / 1000) * 100) / 100;
  if (campaignAfterImpression) {
    const spend = Number(campaignAfterImpression.spend ?? 0);
    const remaining = Number(campaignAfterImpression.remainingBudget ?? 0);
    Math.abs(spend - expectedImpressionCost) < 0.001
      ? pass(`CPM billing correct: spend = ${spend} (expected ${expectedImpressionCost})`)
      : fail(`CPM billing wrong: spend = ${spend} (expected ${expectedImpressionCost})`);
    Math.abs(remaining - (BUDGET - spend)) < 0.001
      ? pass(`remainingBudget correct: ${remaining}`)
      : fail(`remainingBudget wrong: ${remaining} (expected ${BUDGET - spend})`);
  } else {
    fail('adBillingProcessor did not update campaign spend within 15s');
  }

  const impressionAuditSnap = await db
    .collection('adBillingAuditLogs')
    .where('eventId', '==', impressionEventId)
    .limit(1)
    .get();
  if (!impressionAuditSnap.empty) {
    const auditDoc = impressionAuditSnap.docs[0].data();
    log('15 — Impression audit log', auditDoc);
    auditDoc.billingType === 'CPM' ? pass('Audit log billingType = CPM') : fail('Audit log billingType != CPM');
  } else {
    fail('No adBillingAuditLogs entry for impression event');
  }

  // ── STEPS 16-21: Click billing ──────────────────────────────────────────
  console.log('\n── STEPS 16-21: Click Billing ──');
  const spendBeforeClick = campaignAfterImpression
    ? Number(campaignAfterImpression.spend ?? 0)
    : expectedImpressionCost;

  const clickRef = await db.collection('adEngagementEvents').add({
    campaignId: CAMPAIGN_ID,
    userId: 'test_user_5i',
    type: 'click',
    source: 'mobile',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  const clickEventId = clickRef.id;
  log('16 — Click event created', { eventId: clickEventId });

  const campaignAfterClick = await waitForCampaignSpend(CAMPAIGN_ID, spendBeforeClick + 0.01);
  log('17/18/19/20 — Campaign after click', campaignAfterClick);

  if (campaignAfterClick) {
    const clickSpend = Number(campaignAfterClick.spend ?? 0);
    const clickRemaining = Number(campaignAfterClick.remainingBudget ?? 0);
    const expectedClickCost = Math.min(CPC, BUDGET - spendBeforeClick);
    Math.abs(clickSpend - (spendBeforeClick + expectedClickCost)) < 0.001
      ? pass(`CPC billing correct: spend = ${clickSpend}`)
      : fail(`CPC billing wrong: spend = ${clickSpend} (expected ${spendBeforeClick + expectedClickCost})`);
    clickRemaining >= 0
      ? pass(`remainingBudget non-negative: ${clickRemaining}`)
      : fail(`remainingBudget negative: ${clickRemaining}`);
  } else {
    // Budget may already be exhausted from impression — check state
    const snap = await db.collection('adCampaigns').doc(CAMPAIGN_ID).get();
    const data = snap.data();
    if (data?.budgetStatus === 'exhausted') {
      pass('Campaign already exhausted after impression (budget < CPC) — click billing capped correctly');
    } else {
      fail('adBillingProcessor did not update campaign spend for click within 15s');
    }
  }

  const clickAuditSnap = await db
    .collection('adBillingAuditLogs')
    .where('eventId', '==', clickEventId)
    .limit(1)
    .get();
  if (!clickAuditSnap.empty) {
    const clickAudit = clickAuditSnap.docs[0].data();
    log('21 — Click audit log', clickAudit);
    clickAudit.billingType === 'CPC' ? pass('Audit log billingType = CPC') : fail('Audit log billingType != CPC');
  } else {
    // Budget exhausted before click — audit log will show skipped_budget_exhausted
    const skipSnap = await db.collection('adBillingProcessedEvents').doc(clickEventId).get();
    if (skipSnap.exists && skipSnap.data()?.status === 'skipped_budget_exhausted') {
      pass('Click correctly skipped (budget already exhausted at time of click)');
    } else {
      fail('No adBillingAuditLogs entry for click event');
    }
  }

  // ── STEPS 22-24: Idempotency ────────────────────────────────────────────
  console.log('\n── STEPS 22-24: Idempotency Validation ──');

  // Reset campaign for clean idempotency test
  const IDEM_CAMPAIGN_ID = `test_idem_campaign_${Date.now()}`;
  await db.collection('adCampaigns').doc(IDEM_CAMPAIGN_ID).set({
    advertiserId: 'test_advertiser_5i',
    title: 'Idempotency Test Campaign',
    status: 'active',
    deliveryEnabled: true,
    budget: 10,
    spend: 0,
    remainingBudget: 10,
    cpm: CPM,
    costPerClick: CPC,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await db.collection('adEngagementEvents').doc(DUPLICATE_EVENT_ID).set({
    campaignId: IDEM_CAMPAIGN_ID,
    userId: 'test_user_5i',
    type: 'impression',
    source: 'mobile',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await new Promise((r) => setTimeout(r, 6_000));
  const processedSnap1 = await db.collection('adBillingProcessedEvents').doc(DUPLICATE_EVENT_ID).get();
  log('24 — adBillingProcessedEvents record', processedSnap1.data());

  const spendAfterFirst = Number(
    (await db.collection('adCampaigns').doc(IDEM_CAMPAIGN_ID).get()).data()?.spend ?? 0,
  );

  // Simulate duplicate by re-writing same docId (triggers update, function sees same eventId)
  await db.collection('adEngagementEvents').doc(DUPLICATE_EVENT_ID).set(
    { updatedAt: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true },
  );
  await new Promise((r) => setTimeout(r, 6_000));

  const spendAfterDuplicate = Number(
    (await db.collection('adCampaigns').doc(IDEM_CAMPAIGN_ID).get()).data()?.spend ?? 0,
  );

  log('22/23 — Spend after first vs after duplicate attempt', { spendAfterFirst, spendAfterDuplicate });
  processedSnap1.exists
    ? pass('adBillingProcessedEvents record exists (idempotency lock written)')
    : fail('adBillingProcessedEvents record missing');
  Math.abs(spendAfterFirst - spendAfterDuplicate) < 0.001
    ? pass(`Duplicate billing blocked: spend stayed at ${spendAfterFirst}`)
    : fail(`Duplicate billing occurred: spend changed from ${spendAfterFirst} to ${spendAfterDuplicate}`);

  // ── STEPS 25-30: Budget Exhaustion ─────────────────────────────────────
  console.log('\n── STEPS 25-30: Budget Exhaustion Validation ──');
  const EXHAUST_CAMPAIGN_ID = `test_exhaust_campaign_${Date.now()}`;
  const EXHAUST_BUDGET = 0.30; // exactly 3 impressions at KES 0.10 each

  await db.collection('adCampaigns').doc(EXHAUST_CAMPAIGN_ID).set({
    advertiserId: 'test_advertiser_5i',
    title: 'Exhaustion Test Campaign',
    status: 'active',
    deliveryEnabled: true,
    budget: EXHAUST_BUDGET,
    spend: 0,
    remainingBudget: EXHAUST_BUDGET,
    cpm: CPM,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const eventIds: string[] = [];
  for (let i = 0; i < 4; i++) {
    const ref = await db.collection('adEngagementEvents').add({
      campaignId: EXHAUST_CAMPAIGN_ID,
      userId: 'test_user_5i',
      type: 'impression',
      source: 'mobile',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    eventIds.push(ref.id);
    await new Promise((r) => setTimeout(r, 2_000));
  }
  log('25 — Events created to exhaust campaign', { eventIds });

  // Wait for exhaustion
  await new Promise((r) => setTimeout(r, 8_000));
  const exhaustedSnap = await db.collection('adCampaigns').doc(EXHAUST_CAMPAIGN_ID).get();
  const exhaustedData = exhaustedSnap.data();
  log('26/27/28/29 — Exhausted campaign state', exhaustedData);

  exhaustedData?.status === 'paused' ? pass('status = paused') : fail(`status = ${exhaustedData?.status}`);
  exhaustedData?.deliveryEnabled === false ? pass('deliveryEnabled = false') : fail('deliveryEnabled != false');
  exhaustedData?.budgetStatus === 'exhausted' ? pass('budgetStatus = exhausted') : fail(`budgetStatus = ${exhaustedData?.budgetStatus}`);
  Number(exhaustedData?.remainingBudget ?? -1) === 0 ? pass('remainingBudget = 0') : fail(`remainingBudget = ${exhaustedData?.remainingBudget}`);

  const lastAuditSnap = await db
    .collection('adBillingAuditLogs')
    .where('campaignId', '==', EXHAUST_CAMPAIGN_ID)
    .orderBy('createdAt', 'desc')
    .limit(1)
    .get();
  if (!lastAuditSnap.empty) {
    const lastAudit = lastAuditSnap.docs[0].data();
    log('30 — Final audit log record', lastAudit);
    lastAudit.campaignPaused === true
      ? pass('Final audit log shows campaignPaused = true')
      : fail('Final audit log campaignPaused != true');
  } else {
    fail('No audit logs found for exhaustion campaign');
  }

  console.log('\n═══════════════════════════════════════════════════════════');
  console.log('  VALIDATION COMPLETE — see PASS/FAIL above');
  console.log('═══════════════════════════════════════════════════════════\n');
}

main().catch((err) => {
  console.error('Validation script error:', err);
  process.exit(1);
});
