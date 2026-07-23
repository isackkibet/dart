import { Injectable } from '@nestjs/common';

const CDN_PROBE_URL = 'https://cdn.stream.yohpal.com/';
const CACHE_TTL_MS = 30_000;
const PROBE_TIMEOUT_MS = 2_000;

@Injectable()
export class YohPalCdnAvailabilityService {
  private cachedResult: boolean | null = null;
  private cacheExpiresAt = 0;

  async isAvailable(): Promise<boolean> {
    if (Date.now() < this.cacheExpiresAt && this.cachedResult !== null) {
      return this.cachedResult;
    }
    const result = await this.probe();
    this.cachedResult = result;
    this.cacheExpiresAt = Date.now() + CACHE_TTL_MS;
    return result;
  }

  private async probe(): Promise<boolean> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), PROBE_TIMEOUT_MS);
    try {
      const res = await fetch(CDN_PROBE_URL, {
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
}
