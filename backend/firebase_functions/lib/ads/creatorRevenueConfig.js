"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CREATOR_REVENUE_TIERS = void 0;
exports.resolveCreatorTier = resolveCreatorTier;
exports.CREATOR_REVENUE_TIERS = [
    { tier: 'bronze', minConcurrentViewers: 100, creatorSharePercent: 20 },
    { tier: 'silver', minConcurrentViewers: 500, creatorSharePercent: 25 },
    { tier: 'gold', minConcurrentViewers: 2000, creatorSharePercent: 30 },
    { tier: 'diamond', minConcurrentViewers: 10000, creatorSharePercent: 35 },
    { tier: 'elite', minConcurrentViewers: 50000, creatorSharePercent: 40 },
];
function resolveCreatorTier(viewerCount) {
    return ([...exports.CREATOR_REVENUE_TIERS]
        .reverse()
        .find((t) => viewerCount >= t.minConcurrentViewers) ?? null);
}
