import { Injectable } from '@nestjs/common';

export interface QualityInput {
  isLowDataUser: boolean;
  networkType: 'wifi' | '4g' | '3g' | 'unknown';
  deviceTier: 'low' | 'mid' | 'high';
}

@Injectable()
export class YohPalPreloadIntelligenceService {
  getPreloadPriority(score: number): number {
    if (score >= 0.85) return 1;
    if (score >= 0.70) return 2;
    if (score >= 0.55) return 3;
    if (score >= 0.40) return 5;
    return 8;
  }

  recommendQuality(input: QualityInput): '360p' | '480p' | '720p' {
    if (input.isLowDataUser) return '360p';
    if (input.networkType === 'wifi' && input.deviceTier === 'high') return '720p';
    if (input.networkType === '3g') return '360p';
    return '480p';
  }
}
