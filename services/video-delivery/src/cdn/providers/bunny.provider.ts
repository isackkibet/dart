import {
  CdnDeliveryRequest,
  CdnDeliveryResponse,
  CdnProvider,
} from '../cdn-provider.interface';

export class BunnyProvider implements CdnProvider {
  readonly name = 'bunny';

  async isAvailable(): Promise<boolean> {
    return Boolean(process.env.BUNNY_CDN_DOMAIN);
  }

  async sign(request: CdnDeliveryRequest): Promise<CdnDeliveryResponse> {
    const domain = process.env.BUNNY_CDN_DOMAIN;
    return {
      url: `https://${domain}/${request.storagePath}?token=BUNNY_SIGNED_TOKEN`,
      provider: this.name,
      edgeEnabled: true,
      cacheTtlSeconds: 86400,
      headers: {
        'Cache-Control': 'public, max-age=86400',
      },
    };
  }

  async purge(_videoId: string): Promise<void> {
    // Implement BunnyCDN cache purge later.
  }
}
