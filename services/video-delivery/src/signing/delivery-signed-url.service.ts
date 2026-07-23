import { CdnDeliveryService } from '../cdn/cdn-delivery.service';
import { CdnDeliveryResponse } from '../cdn/cdn-provider.interface';

export interface DeliverySignRequest {
  storagePath: string;
  creatorId: string;
  videoId: string;
  quality: '360p' | '480p' | '720p' | 'hls';
  expiresInSeconds?: number;
  preferredProvider?: string;
}

export class DeliverySignedUrlService {
  constructor(private readonly deliveryService: CdnDeliveryService) {}

  async sign(params: DeliverySignRequest): Promise<CdnDeliveryResponse> {
    return this.deliveryService.getDeliveryUrl(
      {
        storagePath: params.storagePath,
        creatorId: params.creatorId,
        videoId: params.videoId,
        quality: params.quality,
        expiresInSeconds: params.expiresInSeconds ?? 900,
      },
      params.preferredProvider,
    );
  }
}
