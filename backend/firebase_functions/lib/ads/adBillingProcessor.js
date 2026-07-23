"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.campaignBudgetStatusUpdater = exports.adBillingProcessor = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const adBillingCalculator_1 = require("./adBillingCalculator");
const db = (0, firestore_2.getFirestore)();
exports.adBillingProcessor = (0, firestore_1.onDocumentCreated)({
    document: 'adEngagementEvents/{eventId}',
    region: 'europe-west2',
    timeoutSeconds: 60,
    memory: '256MiB',
}, async (event) => {
    const eventId = event.params.eventId;
    const eventData = event.data?.data();
    if (!eventData?.campaignId || !eventData?.type)
        return;
    const billingRef = db.collection('adBillingProcessedEvents').doc(eventId);
    const campaignRef = db.collection('adCampaigns').doc(eventData.campaignId);
    await db.runTransaction(async (tx) => {
        const alreadyProcessed = await tx.get(billingRef);
        if (alreadyProcessed.exists)
            return;
        const campaignDoc = await tx.get(campaignRef);
        if (!campaignDoc.exists) {
            tx.set(billingRef, {
                eventId,
                campaignId: eventData.campaignId,
                status: 'skipped_campaign_missing',
                createdAt: firestore_2.FieldValue.serverTimestamp(),
            });
            return;
        }
        const campaign = { id: campaignDoc.id, ...campaignDoc.data() };
        if (campaign.status !== 'active' || campaign.deliveryEnabled === false) {
            tx.set(billingRef, {
                eventId,
                campaignId: campaign.id,
                status: 'skipped_campaign_not_active',
                createdAt: firestore_2.FieldValue.serverTimestamp(),
            });
            return;
        }
        const budget = Number(campaign.budget ?? 0);
        const previousSpend = Number(campaign.spend ?? 0);
        if (budget <= 0 || previousSpend >= budget) {
            tx.update(campaignRef, {
                status: 'paused',
                budgetStatus: 'exhausted',
                deliveryEnabled: false,
                remainingBudget: 0,
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
            });
            tx.set(billingRef, {
                eventId,
                campaignId: campaign.id,
                status: 'skipped_budget_exhausted',
                createdAt: firestore_2.FieldValue.serverTimestamp(),
            });
            return;
        }
        const result = (0, adBillingCalculator_1.calculateAdBilling)(campaign, eventData);
        const chargeableAmount = Math.min(result.billedAmount, Math.max(0, budget - previousSpend));
        const newSpend = (0, adBillingCalculator_1.roundCurrency)(previousSpend + chargeableAmount);
        const remainingBudget = (0, adBillingCalculator_1.roundCurrency)(Math.max(0, budget - newSpend));
        const exhausted = newSpend >= budget;
        tx.update(campaignRef, {
            spend: newSpend,
            remainingBudget,
            budgetStatus: exhausted ? 'exhausted' : 'active',
            status: exhausted ? 'paused' : campaign.status,
            deliveryEnabled: !exhausted,
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        });
        tx.set(billingRef, {
            eventId,
            campaignId: campaign.id,
            status: 'processed',
            billedAmount: chargeableAmount,
            billingType: result.billingType,
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
        tx.set(db.collection('adBillingAuditLogs').doc(), {
            eventId,
            campaignId: campaign.id,
            advertiserId: campaign.advertiserId ?? null,
            billingType: result.billingType,
            eventType: eventData.type,
            billedAmount: chargeableAmount,
            previousSpend,
            newSpend,
            remainingBudget,
            budget,
            campaignPaused: exhausted,
            source: eventData.source ?? 'mobile',
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
    });
});
exports.campaignBudgetStatusUpdater = (0, firestore_1.onDocumentUpdated)({
    document: 'adCampaigns/{campaignId}',
    region: 'europe-west2',
    timeoutSeconds: 60,
    memory: '256MiB',
}, async (event) => {
    const after = event.data?.after.data();
    if (!after)
        return;
    const campaignId = event.params.campaignId;
    const campaignRef = db.collection('adCampaigns').doc(campaignId);
    const budget = Number(after.budget ?? 0);
    const spend = Number(after.spend ?? 0);
    const remainingBudget = (0, adBillingCalculator_1.roundCurrency)(Math.max(0, budget - spend));
    let budgetStatus = 'active';
    if (budget <= 0) {
        budgetStatus = 'paused';
    }
    else if (spend >= budget) {
        budgetStatus = 'exhausted';
    }
    else if (after.status === 'paused') {
        budgetStatus = 'paused';
    }
    const shouldPause = budgetStatus === 'exhausted';
    if (after.remainingBudget === remainingBudget &&
        after.budgetStatus === budgetStatus &&
        after.deliveryEnabled === !shouldPause) {
        return;
    }
    await campaignRef.set({
        remainingBudget,
        budgetStatus,
        deliveryEnabled: shouldPause ? false : (after.deliveryEnabled ?? true),
        status: shouldPause ? 'paused' : after.status,
        updatedAt: firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
});
