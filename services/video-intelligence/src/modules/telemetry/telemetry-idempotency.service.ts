import { Injectable } from '@nestjs/common';

@Injectable()
export class TelemetryIdempotencyService {
  private readonly processedEventIds = new Set<string>();

  isDuplicate(eventId: string): boolean {
    return this.processedEventIds.has(eventId);
  }

  markProcessed(eventId: string): void {
    this.processedEventIds.add(eventId);
  }
}
