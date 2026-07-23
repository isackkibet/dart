import { Injectable } from '@nestjs/common';
import { YohPalVideoAggregate } from '../telemetry/telemetry.entity';

export interface YohPalPreloadUpdate {
  videoId: string;
  preloadPriority: number;
  predictedWatchProbability: number;
}

@Injectable()
export class PreloadRefreshService {
  refresh(
    aggregates: YohPalVideoAggregate[],
    weights: Map<string, number>,
  ): YohPalPreloadUpdate[] {
    return aggregates.map((agg) => {
      const weight = weights.get(agg.videoId) ?? 0;
      return {
        videoId: agg.videoId,
        preloadPriority: this.priorityFromWeight(weight),
        predictedWatchProbability: Math.min(Math.max(weight, 0), 1),
      };
    });
  }

  private priorityFromWeight(weight: number): number {
    if (weight >= 0.85) return 1;
    if (weight >= 0.70) return 2;
    if (weight >= 0.55) return 3;
    if (weight >= 0.40) return 5;
    return 8;
  }
}
