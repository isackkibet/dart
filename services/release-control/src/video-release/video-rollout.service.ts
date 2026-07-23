import { Injectable } from '@nestjs/common';

export interface YohPalRolloutStage {
  label: string;
  percentage: number;
}

export const ROLLOUT_STAGES: YohPalRolloutStage[] = [
  { label: 'Stage 1 — Internal users',   percentage:   1 },
  { label: 'Stage 2 — Pilot users',       percentage:   5 },
  { label: 'Stage 3 — Creators',          percentage:  10 },
  { label: 'Stage 4 — General (25%)',     percentage:  25 },
  { label: 'Stage 5 — General (50%)',     percentage:  50 },
  { label: 'Stage 6 — Full release',      percentage: 100 },
];

@Injectable()
export class YohPalVideoRolloutService {
  isUserEligible(input: {
    userId: string;
    rolloutPercentage: number;
    releaseAllowed: boolean;
  }): boolean {
    if (!input.releaseAllowed) return false;
    const hash = this.hashUserId(input.userId);
    const bucket = hash % 100;
    return bucket < input.rolloutPercentage;
  }

  private hashUserId(userId: string): number {
    let hash = 0;
    for (let i = 0; i < userId.length; i++) {
      hash = (hash << 5) - hash + userId.charCodeAt(i);
      hash |= 0;
    }
    return Math.abs(hash);
  }
}
