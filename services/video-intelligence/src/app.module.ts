import { Module } from '@nestjs/common';
import { TelemetryController } from './modules/telemetry/telemetry.controller';
import { TelemetryRetrySafeController } from './modules/telemetry/telemetry-retry-safe.controller';
import { TelemetryService } from './modules/telemetry/telemetry.service';
import { TelemetryAggregateService } from './modules/telemetry/telemetry-aggregate.service';
import { TelemetryIdempotencyService } from './modules/telemetry/telemetry-idempotency.service';
import { RankingRefreshService } from './modules/ranking/ranking-refresh.service';
import { PreloadRefreshService } from './modules/preload/preload-refresh.service';
import { PerformanceCertificationController } from './modules/performance/performance-certification.controller';
import { PerformanceCertificationService } from './modules/performance/performance-certification.service';
import { PerformanceSummaryService } from './modules/performance/performance-summary.service';
import { PerformanceGateService } from './modules/performance/performance-gate.service';

@Module({
  controllers: [TelemetryController, TelemetryRetrySafeController, PerformanceCertificationController],
  providers: [
    TelemetryService,
    TelemetryAggregateService,
    TelemetryIdempotencyService,
    RankingRefreshService,
    PreloadRefreshService,
    PerformanceCertificationService,
    PerformanceSummaryService,
    PerformanceGateService,
  ],
})
export class AppModule {}
