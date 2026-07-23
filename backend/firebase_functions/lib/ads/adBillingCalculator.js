"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculateAdBilling = calculateAdBilling;
exports.roundCurrency = roundCurrency;
function calculateAdBilling(campaign, event) {
    if (event.type === 'impression') {
        const cpm = Number(campaign.cpm ?? 0);
        const costPerImpression = Number(campaign.costPerImpression ?? 0) || cpm / 1000;
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
function roundCurrency(value) {
    return Math.round(value * 100) / 100;
}
