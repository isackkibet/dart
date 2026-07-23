import { Injectable } from '@nestjs/common';
import { YohPalWatchEventDto } from './telemetry.entity';

@Injectable()
export class TelemetryService {
  async ingest(events: YohPalWatchEventDto[]): Promise<void> {
    const safeEvents = events.filter(
      (event) =>
        event.eventId &&
        event.userId &&
        event.videoId &&
        event.type &&
        event.createdAt,
    );
    await this.persistEvents(safeEvents);
  }

  private async persistEvents(events: YohPalWatchEventDto[]): Promise<YohPalWatchEventDto[]> {
    // Replace with DB insertMany / repository save.
    return events;
  }
}
