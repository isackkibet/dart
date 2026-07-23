import {
  CdnDeliveryRequest,
  CdnDeliveryResponse,
} from './cdn-provider.interface';
import { CdnRoutingService } from './cdn-routing.service';

export class CdnDeliveryService {
  constructor(private readonly routingService: CdnRoutingService) {}

  async getDeliveryUrl(
    request: CdnDeliveryRequest,
    preferredProvider?: string,
  ): Promise<CdnDeliveryResponse> {
    const provider = await this.routingService.selectProvider(preferredProvider);
    return provider.sign(request);
  }
}
