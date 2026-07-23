export type CreatorTier = 'bronze' | 'silver' | 'gold' | 'diamond' | 'elite';

export interface CreatorRevenueTier {
  tier: CreatorTier;
  minConcurrentViewers: number;
  creatorSharePercent: number;
}

export const CREATOR_REVENUE_TIERS: CreatorRevenueTier[] = [
  { tier: 'bronze',  minConcurrentViewers: 100,   creatorSharePercent: 20 },
  { tier: 'silver',  minConcurrentViewers: 500,   creatorSharePercent: 25 },
  { tier: 'gold',    minConcurrentViewers: 2000,  creatorSharePercent: 30 },
  { tier: 'diamond', minConcurrentViewers: 10000, creatorSharePercent: 35 },
  { tier: 'elite',   minConcurrentViewers: 50000, creatorSharePercent: 40 },
];

export function resolveCreatorTier(viewerCount: number): CreatorRevenueTier | null {
  return (
    [...CREATOR_REVENUE_TIERS]
      .reverse()
      .find((t) => viewerCount >= t.minConcurrentViewers) ?? null
  );
}
