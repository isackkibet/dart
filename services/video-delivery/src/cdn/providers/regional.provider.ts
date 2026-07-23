import {
  CdnDeliveryRequest,
  CdnDeliveryResponse,
  CdnProvider,
} from '../cdn-provider.interface';

export class RegionalProvider implements CdnProvider {
  readonly name = 'regional';

  async isAvailable(): Promise<boolean> {
    return Boolean(process.env.REGIONAL_CDN_DOMAIN);
  }

  async sign(request: CdnDeliveryRequest): Promise<CdnDeliveryResponse> {
    const domain = process.env.REGIONAL_CDN_DOMAIN;
    return {
      url: `https://${domain}/${request.storagePath}?token=REGIONAL_SIGNED_TOKEN`,
      provider: this.name,
      edgeEnabled: true,
      cacheTtlSeconds: 43200,
      headers: {
        'Cache-Control': 'public, max-age=43200',
      },
    };
  }

  async purge(_videoId: string): Promise<void> {
    // Implement regional CDN cache purge later.
  }
}
