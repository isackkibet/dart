import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { YohPalVideoReleaseGateService } from './video-release-gate.service';
import { YohPalVideoRolloutService } from './video-rollout.service';
import { YohPalVideoKillSwitchService } from './video-kill-switch.service';
import { YohPalVideoReleaseLock } from './video-release-lock.entity';

@Controller('video-release')
export class YohPalVideoReleaseController {
  constructor(
    private readonly gateService: YohPalVideoReleaseGateService,
    private readonly rolloutService: YohPalVideoRolloutService,
    private readonly killSwitchService: YohPalVideoKillSwitchService,
  ) {}

  @Post('evaluate')
  evaluate(@Body() lock: YohPalVideoReleaseLock) {
    return this.gateService.canRelease(lock);
  }

  @Post('eligible/:userId')
  eligible(
    @Param('userId') userId: string,
    @Body() body: { lock: YohPalVideoReleaseLock },
  ) {
    const gate = this.gateService.canRelease(body.lock);
    return {
      userId,
      eligible: this.rolloutService.isUserEligible({
        userId,
        rolloutPercentage: body.lock.rolloutPercentage,
        releaseAllowed: gate.allowed,
      }),
      blockers: gate.blockers,
    };
  }

  @Post('kill-switch/enable')
  enableKillSwitch(@Body() body: { reason: string }) {
    return this.killSwitchService.enable(body.reason);
  }

  @Post('kill-switch/disable')
  disableKillSwitch() {
    return this.killSwitchService.disable();
  }

  @Get('kill-switch/status')
  killSwitchStatus() {
    return this.killSwitchService.status();
  }
}
