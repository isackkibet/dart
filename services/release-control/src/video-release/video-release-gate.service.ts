import { Injectable } from '@nestjs/common';
import { YohPalVideoReleaseLock } from './video-release-lock.entity';

@Injectable()
export class YohPalVideoReleaseGateService {
  canRelease(lock: YohPalVideoReleaseLock): {
    allowed: boolean;
    blockers: string[];
  } {
    const blockers: string[] = [];

    if (!lock.androidPassed)   blockers.push('Android certification failed');
    if (!lock.iosPassed)       blockers.push('iOS certification failed');
    if (!lock.noCdnPassed)     blockers.push('No-CDN playback failed');
    if (!lock.startupPassed)   blockers.push('Startup gate failed');
    if (!lock.bufferingPassed) blockers.push('Buffering gate failed');
    if (!lock.memoryPassed)    blockers.push('Memory gate failed');
    if (!lock.cachePassed)     blockers.push('Cache gate failed');
    if (!lock.stabilityPassed)           blockers.push('30-minute stability gate failed');
    if (!lock.hlsStandardizationPassed)  blockers.push('HLS segment naming not standardised (V13 Sprint B)');
    if (!lock.cdnManifestRewritePassed)  blockers.push('CDN manifest still references firebasestorage.googleapis.com (V13 Sprint C)');
    if (!lock.mpesaPayoutFunctionDeployed) blockers.push('triggerMpesaPayout Cloud Function not deployed (V13 Sprint D)');
    if (!lock.networkTypeWiringPassed)   blockers.push('Flutter networkType not wired to feed API (V13 Sprint F)');

    if (!lock.approverName || !lock.approverRole) {
      blockers.push('Release approval missing');
    }
    if (lock.rolloutPercentage <= 0 || lock.rolloutPercentage > 100) {
      blockers.push('Invalid rollout percentage');
    }
    if (lock.killSwitchEnabled) {
      blockers.push('Kill switch is enabled');
    }

    return { allowed: blockers.length === 0, blockers };
  }
}
