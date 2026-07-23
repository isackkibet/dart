import {
  CdnDeliveryRequest,
  CdnDeliveryResponse,
  CdnProvider,
} from '../cdn-provider.interface';

export class CloudFrontProvider implements CdnProvider {
  readonly name = 'cloudfront';

  async isAvailable(): Promise<boolean> {
    return Boolean(process.env.CLOUDFRONT_DOMAIN);
  }

  async sign(request: CdnDeliveryRequest): Promise<CdnDeliveryResponse> {
    const domain = process.env.CLOUDFRONT_DOMAIN;
    return {
      url: `https://${domain}/${request.storagePath}?Policy=CLOUDFRONT_POLICY&Signature=CLOUDFRONT_SIGNATURE`,
      provider: this.name,
      edgeEnabled: true,
      cacheTtlSeconds: 86400,
      headers: {
        'Cache-Control': 'public, max-age=86400',
      },
    };
  }

  async purge(_videoId: string): Promise<void> {
    // Implement CloudFront invalidation later.
  }
}
