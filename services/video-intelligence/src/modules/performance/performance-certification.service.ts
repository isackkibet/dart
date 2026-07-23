import { Injectable } from '@nestjs/common';
import { YohPalVideoPerformanceMetric } from './performance-metric.entity';
import { PerformanceGateService } from './performance-gate.service';
import { PerformanceSummaryService } from './performance-summary.service';

@Injectable()
export class PerformanceCertificationService {
  private readonly metrics: YohPalVideoPerformanceMetric[] = [];

  constructor(
    private readonly summaryService: PerformanceSummaryService,
    private readonly gateService: PerformanceGateService,
  ) {}

  async ingest(metrics: YohPalVideoPerformanceMetric[]): Promise<{ accepted: number }> {
    this.metrics.push(...metrics);
    return { accepted: metrics.length };
  }

  async certify(sessionId: string) {
    const sessionMetrics = this.metrics.filter(
      (m) => m.testSessionId === sessionId,
    );
    const summary = this.summaryService.summarize(sessionId, sessionMetrics);
    const gate = this.gateService.evaluate(summary);

    return {
      ...summary,
      certifiedForControlledRelease: gate.passed,
      blockers: gate.blockers,
    };
  }
}
