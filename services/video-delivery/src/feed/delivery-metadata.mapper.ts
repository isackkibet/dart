import { CdnDeliveryService } from '../cdn/cdn-delivery.service';
import { CdnDeliveryResponse } from '../cdn/cdn-provider.interface';

export type YohPalDeliveryMetadata = CdnDeliveryResponse;

export interface YohPalFeedDeliverySet {
  low360: YohPalDeliveryMetadata;
  medium480: YohPalDeliveryMetadata;
  high720: YohPalDeliveryMetadata;
  hls?: YohPalDeliveryMetadata;
}

export class DeliveryMetadataMapper {
  async mapVideoDelivery(input: {
    videoId: string;
    creatorId: string;
    storageBasePath: string;
    hlsMasterPath?: string;
    deliveryService: CdnDeliveryService;
  }): Promise<YohPalFeedDeliverySet> {
    const { videoId, creatorId, storageBasePath, deliveryService } = input;

    const [low360, medium480, high720] = await Promise.all([
      deliveryService.getDeliveryUrl({
        storagePath: `${storageBasePath}/360p.mp4`,
        creatorId,
        videoId,
        quality: '360p',
        expiresInSeconds: 900,
      }),
      deliveryService.getDeliveryUrl({
        storagePath: `${storageBasePath}/480p.mp4`,
        creatorId,
        videoId,
        quality: '480p',
        expiresInSeconds: 900,
      }),
      deliveryService.getDeliveryUrl({
        storagePath: `${storageBasePath}/720p.mp4`,
        creatorId,
        videoId,
        quality: '720p',
        expiresInSeconds: 900,
      }),
    ]);

    const hls = input.hlsMasterPath
      ? await deliveryService.getDeliveryUrl({
          storagePath: input.hlsMasterPath,
          creatorId,
          videoId,
          quality: 'hls',
          expiresInSeconds: 900,
        })
      : undefined;

    return { low360, medium480, high720, hls };
  }
}
