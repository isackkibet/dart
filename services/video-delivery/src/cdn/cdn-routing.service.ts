import { CdnProvider } from './cdn-provider.interface';

export class CdnRoutingService {
  constructor(private readonly providers: CdnProvider[]) {}

  async selectProvider(preferredProvider?: string): Promise<CdnProvider> {
    if (preferredProvider) {
      const preferred = this.providers.find(
        (p) => p.name === preferredProvider,
      );
      if (preferred && (await preferred.isAvailable())) {
        return preferred;
      }
    }

    for (const provider of this.providers) {
      if (provider.name !== 'origin' && (await provider.isAvailable())) {
        return provider;
      }
    }

    const origin = this.providers.find((p) => p.name === 'origin');
    if (!origin) {
      throw new Error('No video delivery provider available');
    }
    return origin;
  }
}
