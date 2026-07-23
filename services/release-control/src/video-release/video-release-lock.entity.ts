export type YohPalVideoReleaseStatus =
  | 'LOCKED'
  | 'APPROVED'
  | 'ROLLOUT'
  | 'PAUSED'
  | 'REJECTED';

export interface YohPalVideoReleaseLock {
  releaseId: string;
  version: string;
  certificationSessionId: string;
  // Core device certification
  androidPassed: boolean;
  iosPassed: boolean;
  // Playback quality
  noCdnPassed: boolean;
  startupPassed: boolean;
  bufferingPassed: boolean;
  memoryPassed: boolean;
  cachePassed: boolean;
  stabilityPassed: boolean;
  // V13 — Production Stabilization
  hlsStandardizationPassed: boolean;   // playlist_NNNp.m3u8 + vNNNp_%03d.ts naming verified
  cdnManifestRewritePassed: boolean;   // no firebasestorage.googleapis.com in served manifests
  mpesaPayoutFunctionDeployed: boolean; // triggerMpesaPayout callable confirmed
  networkTypeWiringPassed: boolean;    // Flutter passes real connectivity_plus type to feed API
  // Approval
  approverName: string;
  approverRole: string;
  approvedAt: Date;
  rolloutPercentage: number;
  killSwitchEnabled: boolean;
  status: YohPalVideoReleaseStatus;
}

export interface V13CertificationInput {
  androidPassed: boolean;
  iosPassed: boolean;
  noCdnPassed: boolean;
  startupPassed: boolean;
  bufferingPassed: boolean;
  memoryPassed: boolean;
  cachePassed: boolean;
  stabilityPassed: boolean;
  hlsStandardizationPassed: boolean;
  cdnManifestRewritePassed: boolean;
  mpesaPayoutFunctionDeployed: boolean;
  networkTypeWiringPassed: boolean;
  approverName: string;
  approverRole: string;
  rolloutPercentage: number;
}

export function computeReleaseCertification(
  input: V13CertificationInput,
): { lock: Omit<YohPalVideoReleaseLock, 'releaseId' | 'certificationSessionId'>; blockers: string[] } {
  const blockers: string[] = [];

  if (!input.androidPassed)              blockers.push('Android 30-min certification failed');
  if (!input.iosPassed)                  blockers.push('iOS 30-min certification failed');
  if (!input.noCdnPassed)               blockers.push('No-CDN fallback playback failed');
  if (!input.startupPassed)             blockers.push('Startup gate failed');
  if (!input.bufferingPassed)           blockers.push('Buffering gate failed');
  if (!input.memoryPassed)              blockers.push('Memory gate failed');
  if (!input.cachePassed)               blockers.push('CDN cache-header gate failed');
  if (!input.stabilityPassed)           blockers.push('30-minute stability gate failed');
  if (!input.hlsStandardizationPassed)  blockers.push('HLS segment naming not standardised (V13 Sprint B)');
  if (!input.cdnManifestRewritePassed)  blockers.push('CDN manifest still references firebasestorage.googleapis.com (V13 Sprint C)');
  if (!input.mpesaPayoutFunctionDeployed) blockers.push('triggerMpesaPayout Cloud Function not deployed (V13 Sprint D)');
  if (!input.networkTypeWiringPassed)   blockers.push('Flutter networkType not wired to feed API (V13 Sprint F)');
  if (!input.approverName || !input.approverRole) blockers.push('Release approval missing');
  if (input.rolloutPercentage <= 0 || input.rolloutPercentage > 100) blockers.push('Invalid rollout percentage');

  const status: YohPalVideoReleaseStatus = blockers.length === 0 ? 'APPROVED' : 'LOCKED';

  return {
    blockers,
    lock: {
      version: 'v13',
      androidPassed: input.androidPassed,
      iosPassed: input.iosPassed,
      noCdnPassed: input.noCdnPassed,
      startupPassed: input.startupPassed,
      bufferingPassed: input.bufferingPassed,
      memoryPassed: input.memoryPassed,
      cachePassed: input.cachePassed,
      stabilityPassed: input.stabilityPassed,
      hlsStandardizationPassed: input.hlsStandardizationPassed,
      cdnManifestRewritePassed: input.cdnManifestRewritePassed,
      mpesaPayoutFunctionDeployed: input.mpesaPayoutFunctionDeployed,
      networkTypeWiringPassed: input.networkTypeWiringPassed,
      approverName: input.approverName,
      approverRole: input.approverRole,
      approvedAt: new Date(),
      rolloutPercentage: input.rolloutPercentage,
      killSwitchEnabled: false,
      status,
    },
  };
}
