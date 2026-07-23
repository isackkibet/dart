import { Injectable } from '@nestjs/common';
import { YohPalVideoPerformanceMetric } from './performance-metric.entity';

export interface YohPalVideoCertificationSummary {
  sessionId: string;
  avgStartupMs: number;
  p95StartupMs: number;
  avgBufferingMs: number;
  bufferingRate: number;
  avgScrollFps: number;
  avgMemoryMb: number;
  droppedFramesTotal: number;
  cacheHitRate: number;
  playbackErrorRate: number;
  originUsageRate: number;
  cdnUsageRate: number;
  mp4UsageRate: number;
  hlsUsageRate: number;
  thirtyMinuteStabilityPassed: boolean;
  certifiedForControlledRelease: boolean;
  blockers: string[];
}

@Injectable()
export class PerformanceSummaryService {
  summarize(
    sessionId: string,
    metrics: YohPalVideoPerformanceMetric[],
  ): YohPalVideoCertificationSummary {
    if (metrics.length === 0) {
      return this.emptySummary(sessionId);
    }

    const startupValues = metrics.map((m) => m.startupMs).sort((a, b) => a - b);
    const p95Index = Math.min(
      Math.floor(startupValues.length * 0.95),
      startupValues.length - 1,
    );

    const avg = (values: number[]) =>
      values.reduce((a, b) => a + b, 0) / values.length;

    const cacheHits = metrics.filter((m) => m.cacheHit).length;
    const playbackErrors = metrics.filter((m) => m.playbackError).length;
    const originUsage = metrics.filter((m) => m.deliveryProvider === 'origin').length;
    const mp4Usage = metrics.filter((m) => m.deliveryMode === 'mp4').length;

    return {
      sessionId,
      avgStartupMs: avg(startupValues),
      p95StartupMs: startupValues[p95Index] ?? 0,
      avgBufferingMs: avg(metrics.map((m) => m.bufferingMs)),
      bufferingRate: metrics.filter((m) => m.bufferingMs > 0).length / metrics.length,
      avgScrollFps: avg(metrics.map((m) => m.scrollFps)),
      avgMemoryMb: avg(metrics.map((m) => m.memoryMb)),
      droppedFramesTotal: metrics.reduce((sum, m) => sum + m.droppedFrames, 0),
      cacheHitRate: cacheHits / metrics.length,
      playbackErrorRate: playbackErrors / metrics.length,
      originUsageRate: originUsage / metrics.length,
      cdnUsageRate: (metrics.length - originUsage) / metrics.length,
      mp4UsageRate: mp4Usage / metrics.length,
      hlsUsageRate: (metrics.length - mp4Usage) / metrics.length,
      thirtyMinuteStabilityPassed: metrics.length >= 30 && playbackErrors === 0,
      certifiedForControlledRelease: false,
      blockers: [],
    };
  }

  private emptySummary(sessionId: string): YohPalVideoCertificationSummary {
    return {
      sessionId,
      avgStartupMs: 0, p95StartupMs: 0, avgBufferingMs: 0,
      bufferingRate: 0, avgScrollFps: 0, avgMemoryMb: 0,
      droppedFramesTotal: 0, cacheHitRate: 0, playbackErrorRate: 0,
      originUsageRate: 0, cdnUsageRate: 0, mp4UsageRate: 0, hlsUsageRate: 0,
      thirtyMinuteStabilityPassed: false,
      certifiedForControlledRelease: false,
      blockers: ['No metrics submitted for this session'],
    };
  }
}
