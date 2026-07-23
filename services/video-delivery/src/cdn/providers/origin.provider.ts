import {
  CdnDeliveryRequest,
  CdnDeliveryResponse,
  CdnProvider,
} from '../cdn-provider.interface';

export class OriginProvider implements CdnProvider {
  readonly name = 'origin';

  async isAvailable(): Promise<boolean> {
    return true;
  }

  async sign(request: CdnDeliveryRequest): Promise<CdnDeliveryResponse> {
    return {
      url: `${request.storagePath}?signature=ORIGIN_SIGNED_TOKEN&expiresIn=${request.expiresInSeconds}`,
      provider: this.name,
      edgeEnabled: false,
      cacheTtlSeconds: 300,
      headers: {
        'Cache-Control': 'private, max-age=300',
      },
    };
  }
}
