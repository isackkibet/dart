import { Injectable } from '@nestjs/common';
import { YohPalVideoCertificationSummary } from './performance-summary.service';

@Injectable()
export class PerformanceGateService {
  evaluate(summary: YohPalVideoCertificationSummary): {
    passed: boolean;
    blockers: string[];
  } {
    const blockers: string[] = [];

    if (summary.p95StartupMs > 1500) {
      blockers.push('P95 startup time exceeds 1500ms');
    }
    if (summary.avgBufferingMs > 1000) {
      blockers.push('Average buffering time exceeds 1000ms');
    }
    if (summary.avgScrollFps < 55) {
      blockers.push('Average feed scroll FPS is below 55');
    }
    if (summary.avgMemoryMb > 700) {
      blockers.push('Average memory usage exceeds 700MB');
    }
    if (summary.playbackErrorRate > 0.02) {
      blockers.push('Playback error rate exceeds 2%');
    }
    if (!summary.thirtyMinuteStabilityPassed) {
      blockers.push('30-minute stability test failed');
    }

    return { passed: blockers.length === 0, blockers };
  }
}
