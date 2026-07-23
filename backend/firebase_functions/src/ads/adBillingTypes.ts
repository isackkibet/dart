export type AdEngagementType = 'impression' | 'click';

export interface AdCampaign {
  id: string;
  advertiserId: string;
  status: string;
  deliveryEnabled?: boolean;
  budget: number;
  spend?: number;
  remainingBudget?: number;
  cpm?: number;
  cpc?: number;
  costPerImpression?: number;
  costPerClick?: number;
  budgetStatus?: string;
}

export interface AdEngagementEvent {
  campaignId: string;
  userId: string;
  type: AdEngagementType;
  source?: string;
}

export interface BillingResult {
  billingType: 'CPM' | 'CPC';
  billedAmount: number;
}
