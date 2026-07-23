import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { PerformanceCertificationService } from './performance-certification.service';
import { YohPalVideoPerformanceMetric } from './performance-metric.entity';

@Controller('video-performance')
export class PerformanceCertificationController {
  constructor(
    private readonly certificationService: PerformanceCertificationService,
  ) {}

  @Post('metrics')
  async ingest(@Body() body: { metrics: YohPalVideoPerformanceMetric[] }) {
    return this.certificationService.ingest(body.metrics);
  }

  @Get('certification/:sessionId')
  async certify(@Param('sessionId') sessionId: string) {
    return this.certificationService.certify(sessionId);
  }
}
