import { Body, Controller, Post } from '@nestjs/common';
import { TelemetryService } from './telemetry.service';
import { TelemetryIdempotencyService } from './telemetry-idempotency.service';
import { YohPalWatchEventDto } from './telemetry.entity';

@Controller('video-telemetry')
export class TelemetryRetrySafeController {
  constructor(
    private readonly telemetryService: TelemetryService,
    private readonly idempotencyService: TelemetryIdempotencyService,
  ) {}

  @Post('events/retry-safe')
  async ingestRetrySafe(@Body() body: { events: YohPalWatchEventDto[] }) {
    const accepted: YohPalWatchEventDto[] = [];
    const acceptedEventIds: string[] = [];

    for (const event of body.events) {
      if (this.idempotencyService.isDuplicate(event.eventId)) {
        acceptedEventIds.push(event.eventId);
        continue;
      }
      accepted.push(event);
      acceptedEventIds.push(event.eventId);
      this.idempotencyService.markProcessed(event.eventId);
    }

    if (accepted.length > 0) {
      await this.telemetryService.ingest(accepted);
    }

    return { accepted: accepted.length, acceptedEventIds };
  }
}
