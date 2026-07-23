import { Injectable } from '@nestjs/common';

export interface YohPalDeliveryInput {
  hlsReady: boolean;
  cdnAvailable: boolean;
  networkType: 'wifi' | '5g' | '4g' | '3g' | '2g' | 'unknown';
  lowDataMode: boolean;
}

export interface YohPalDeliveryDecision {
  recommendedDelivery: 'mp4' | 'hls';
  recommendedQuality: '360p' | '480p' | '720p' | 'auto';
}

@Injectable()
export class YohPalDeliveryDecisionService {
  decide(input: YohPalDeliveryInput): YohPalDeliveryDecision {
    if (input.hlsReady) {
      const slowNetwork = input.lowDataMode || input.networkType === '3g' || input.networkType === '2g';
      return {
        recommendedDelivery: 'hls',
        recommendedQuality: slowNetwork ? '360p' : '720p',
      };
    }
    if (input.lowDataMode || input.networkType === '3g' || input.networkType === '2g') {
      return { recommendedDelivery: 'mp4', recommendedQuality: '360p' };
    }
    if (input.networkType === 'wifi') {
      return { recommendedDelivery: 'mp4', recommendedQuality: '720p' };
    }
    return { recommendedDelivery: 'mp4', recommendedQuality: '480p' };
  }
}
