export interface ExposureSyncReceipt {
  viewerId: string;
  acceptedCount: number;
  rejectedCount: number;
  highestServerSequence: number;
  synchronizedAt: string;
  releaseTag: string;
  commitHash: string;
}
