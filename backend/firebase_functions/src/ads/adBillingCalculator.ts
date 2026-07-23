import { AdCampaign, AdEngagementEvent, BillingResult } from './adBillingTypes';

export function calculateAdBilling(
  campaign: AdCampaign,
  event: AdEngagementEvent,
): BillingResult {
  if (event.type === 'impression') {
    const cpm = Number(campaign.cpm ?? 0);
    const costPerImpression =
      Number(campaign.costPerImpression ?? 0) || cpm / 1000;
    return {
      billingType: 'CPM',
      billedAmount: roundCurrency(costPerImpression),
    };
  }

  if (event.type === 'click') {
    const costPerClick = Number(campaign.costPerClick ?? campaign.cpc ?? 0);
    return {
      billingType: 'CPC',
      billedAmount: roundCurrency(costPerClick),
    };
  }

  throw new Error(`Unsupported ad engagement type: ${event.type}`);
}

export function roundCurrency(value: number): number {
  return Math.round(value * 100) / 100;
}
