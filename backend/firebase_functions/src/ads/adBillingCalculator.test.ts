import { calculateAdBilling } from './adBillingCalculator';

describe('calculateAdBilling', () => {
  it('calculates CPM impression billing from cpm', () => {
    const result = calculateAdBilling(
      {
        id: 'campaign_1',
        advertiserId: 'adv_1',
        status: 'active',
        budget: 1000,
        spend: 0,
        cpm: 100,
      },
      {
        campaignId: 'campaign_1',
        userId: 'user_1',
        type: 'impression',
      },
    );
    expect(result.billingType).toBe('CPM');
    expect(result.billedAmount).toBe(0.1);
  });

  it('calculates CPC click billing', () => {
    const result = calculateAdBilling(
      {
        id: 'campaign_1',
        advertiserId: 'adv_1',
        status: 'active',
        budget: 1000,
        spend: 0,
        costPerClick: 5,
      },
      {
        campaignId: 'campaign_1',
        userId: 'user_1',
        type: 'click',
      },
    );
    expect(result.billingType).toBe('CPC');
    expect(result.billedAmount).toBe(5);
  });

  it('uses costPerImpression when provided', () => {
    const result = calculateAdBilling(
      {
        id: 'campaign_1',
        advertiserId: 'adv_1',
        status: 'active',
        budget: 1000,
        spend: 0,
        costPerImpression: 0.25,
      },
      {
        campaignId: 'campaign_1',
        userId: 'user_1',
        type: 'impression',
      },
    );
    expect(result.billingType).toBe('CPM');
    expect(result.billedAmount).toBe(0.25);
  });

  it('uses cpc field when costPerClick is absent', () => {
    const result = calculateAdBilling(
      {
        id: 'campaign_1',
        advertiserId: 'adv_1',
        status: 'active',
        budget: 1000,
        spend: 0,
        cpc: 2.5,
      },
      {
        campaignId: 'campaign_1',
        userId: 'user_1',
        type: 'click',
      },
    );
    expect(result.billingType).toBe('CPC');
    expect(result.billedAmount).toBe(2.5);
  });

  it('rounds billing amounts to 2 decimal places', () => {
    const result = calculateAdBilling(
      {
        id: 'campaign_1',
        advertiserId: 'adv_1',
        status: 'active',
        budget: 1000,
        spend: 0,
        cpm: 33,
      },
      {
        campaignId: 'campaign_1',
        userId: 'user_1',
        type: 'impression',
      },
    );
    expect(result.billingType).toBe('CPM');
    expect(result.billedAmount).toBe(0.03);
  });
});
