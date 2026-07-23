import { Module } from '@nestjs/common';
import { YohPalVideoReleaseController } from './video-release/video-release.controller';
import { YohPalVideoReleaseGateService } from './video-release/video-release-gate.service';
import { YohPalVideoRolloutService } from './video-release/video-rollout.service';
import { YohPalVideoKillSwitchService } from './video-release/video-kill-switch.service';

@Module({
  controllers: [YohPalVideoReleaseController],
  providers: [
    YohPalVideoReleaseGateService,
    YohPalVideoRolloutService,
    YohPalVideoKillSwitchService,
  ],
})
export class AppModule {}
