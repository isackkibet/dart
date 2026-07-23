import { Injectable } from '@nestjs/common';
import { YohPalVideoAggregate, YohPalWatchEventDto } from './telemetry.entity';

@Injectable()
export class TelemetryAggregateService {
  aggregate(events: YohPalWatchEventDto[]): YohPalVideoAggregate[] {
    const map = new Map<string, YohPalVideoAggregate>();

    for (const event of events) {
      if (!map.has(event.videoId)) {
        map.set(event.videoId, {
          videoId: event.videoId,
          impressions: 0,
          plays: 0,
          skips: 0,
          completions: 0,
          replays: 0,
          likes: 0,
          comments: 0,
          shares: 0,
          totalStartupMs: 0,
          startupSamples: 0,
          totalBufferingMs: 0,
          bufferingSamples: 0,
        });
      }

      const aggregate = map.get(event.videoId)!;

      if (event.type === 'impression') aggregate.impressions++;
      if (event.type === 'play') aggregate.plays++;
      if (event.type === 'skip') aggregate.skips++;
      if (event.type === 'complete') aggregate.completions++;
      if (event.type === 'replay') aggregate.replays++;
      if (event.type === 'like') aggregate.likes++;
      if (event.type === 'comment') aggregate.comments++;
      if (event.type === 'share') aggregate.shares++;

      if (event.startupMs) {
        aggregate.totalStartupMs += event.startupMs;
        aggregate.startupSamples++;
      }

      if (event.bufferingMs) {
        aggregate.totalBufferingMs += event.bufferingMs;
        aggregate.bufferingSamples++;
      }
    }

    return [...map.values()];
  }
}
