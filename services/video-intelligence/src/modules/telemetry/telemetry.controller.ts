import { Body, Controller, Post } from '@nestjs/common';
import { TelemetryService } from './telemetry.service';
import { YohPalWatchEventDto } from './telemetry.entity';

@Controller('video-telemetry')
export class TelemetryController {
  constructor(private readonly telemetryService: TelemetryService) {}

  @Post('events')
  async ingest(@Body() body: { events: YohPalWatchEventDto[] }) {
    await this.telemetryService.ingest(body.events);
    return { accepted: body.events.length };
  }
}
