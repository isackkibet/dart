export type VideoProcessingStatus =
  | 'UPLOADED'
  | 'TRANSCODING'
  | 'READY'
  | 'FAILED';

export interface YohPalVideoEntity {
  id: string;
  creatorId: string;
  originalUrl: string;
  low360Url?: string;
  medium480Url?: string;
  high720Url?: string;
  hlsMasterUrl?: string;
  hls360Url?: string;
  hls480Url?: string;
  hls720Url?: string;
  hlsReady: boolean;
  mp4Ready: boolean;
  durationSeconds?: number;
  status: VideoProcessingStatus;
  createdAt: Date;
  updatedAt: Date;
  // Ranking signals — populated by engagement tracking (V6+)
  creatorScore?: number;
  completionRate?: number;
  replayRate?: number;
  likeRate?: number;
  commentRate?: number;
  shareRate?: number;
  reportPenalty?: number;
  freshnessBoost?: number;
}
