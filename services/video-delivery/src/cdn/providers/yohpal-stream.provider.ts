import {
  CdnDeliveryRequest,
  CdnDeliveryResponse,
  CdnProvider,
} from '../cdn-provider.interface';

const CDN_BASE = 'https://cdn.stream.yohpal.com';
const PROBE_TIMEOUT_MS = 2_000;

export class YohPalStreamProvider implements CdnProvider {
  readonly name = 'yohpal-stream';

  async isAvailable(): Promise<boolean> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), PROBE_TIMEOUT_MS);
    try {
      const res = await fetch(`${CDN_BASE}/`, {
        method: 'HEAD',
        signal: controller.signal,
      });
      return res.status < 500;
    } catch {
      return false;
    } finally {
      clearTimeout(timer);
    }
  }

  async sign(request: CdnDeliveryRequest): Promise<CdnDeliveryResponse> {
    return {
      url: `${CDN_BASE}/${request.storagePath}`,
      provider: this.name,
      edgeEnabled: true,
      cacheTtlSeconds: 86400,
      headers: {
        'Cache-Control': 'public, max-age=86400',
      },
    };
  }

  async purge(_videoId: string): Promise<void> {
    // Purge via yohpal-stream API — implement when purge endpoint is available.
  }
}
