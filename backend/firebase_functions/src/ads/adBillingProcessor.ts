import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { calculateAdBilling, roundCurrency } from './adBillingCalculator';
import { AdCampaign, AdEngagementEvent } from './adBillingTypes';

const db = getFirestore();

export const adBillingProcessor = onDocumentCreated(
  {
    document: 'adEngagementEvents/{eventId}',
    region: 'europe-west2',
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  async (event) => {
    const eventId = event.params.eventId;
    const eventData = event.data?.data() as AdEngagementEvent | undefined;

    if (!eventData?.campaignId || !eventData?.type) return;

    const billingRef = db.collection('adBillingProcessedEvents').doc(eventId);
    const campaignRef = db.collection('adCampaigns').doc(eventData.campaignId);

    await db.runTransaction(async (tx) => {
      const alreadyProcessed = await tx.get(billingRef);
      if (alreadyProcessed.exists) return;

      const campaignDoc = await tx.get(campaignRef);
      if (!campaignDoc.exists) {
        tx.set(billingRef, {
          eventId,
          campaignId: eventData.campaignId,
          status: 'skipped_campaign_missing',
          createdAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      const campaign = { id: campaignDoc.id, ...campaignDoc.data() } as AdCampaign;

      if (campaign.status !== 'active' || campaign.deliveryEnabled === false) {
        tx.set(billingRef, {
          eventId,
          campaignId: campaign.id,
          status: 'skipped_campaign_not_active',
          createdAt: FieldValue.serverTimestamp(),
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
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.set(billingRef, {
          eventId,
          campaignId: campaign.id,
          status: 'skipped_budget_exhausted',
          createdAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      const result = calculateAdBilling(campaign, eventData);
      const chargeableAmount = Math.min(
        result.billedAmount,
        Math.max(0, budget - previousSpend),
      );
      const newSpend = roundCurrency(previousSpend + chargeableAmount);
      const remainingBudget = roundCurrency(Math.max(0, budget - newSpend));
      const exhausted = newSpend >= budget;

      tx.update(campaignRef, {
        spend: newSpend,
        remainingBudget,
        budgetStatus: exhausted ? 'exhausted' : 'active',
        status: exhausted ? 'paused' : campaign.status,
        deliveryEnabled: !exhausted,
        updatedAt: FieldValue.serverTimestamp(),
      });

      tx.set(billingRef, {
        eventId,
        campaignId: campaign.id,
        status: 'processed',
        billedAmount: chargeableAmount,
        billingType: result.billingType,
        createdAt: FieldValue.serverTimestamp(),
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
        createdAt: FieldValue.serverTimestamp(),
      });
    });
  },
);

export const campaignBudgetStatusUpdater = onDocumentUpdated(
  {
    document: 'adCampaigns/{campaignId}',
    region: 'europe-west2',
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  async (event) => {
    const after = event.data?.after.data() as AdCampaign | undefined;
    if (!after) return;

    const campaignId = event.params.campaignId;
    const campaignRef = db.collection('adCampaigns').doc(campaignId);

    const budget = Number(after.budget ?? 0);
    const spend = Number(after.spend ?? 0);
    const remainingBudget = roundCurrency(Math.max(0, budget - spend));

    let budgetStatus = 'active';
    if (budget <= 0) {
      budgetStatus = 'paused';
    } else if (spend >= budget) {
      budgetStatus = 'exhausted';
    } else if (after.status === 'paused') {
      budgetStatus = 'paused';
    }

    const shouldPause = budgetStatus === 'exhausted';

    if (
      after.remainingBudget === remainingBudget &&
      after.budgetStatus === budgetStatus &&
      after.deliveryEnabled === !shouldPause
    ) {
      return;
    }

    await campaignRef.set(
      {
        remainingBudget,
        budgetStatus,
        deliveryEnabled: shouldPause ? false : (after.deliveryEnabled ?? true),
        status: shouldPause ? 'paused' : after.status,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);
