export type YohPalWatchEventType =
  | 'impression'
  | 'play'
  | 'pause'
  | 'skip'
  | 'complete'
  | 'replay'
  | 'like'
  | 'comment'
  | 'share'
  | 'bufferStart'
  | 'bufferEnd'
  | 'startupMeasured'
  | 'error';

export interface YohPalWatchEventDto {
  eventId: string;
  userId: string;
  videoId: string;
  type: YohPalWatchEventType;
  positionMs: number;
  durationMs: number;
  startupMs?: number;
  bufferingMs?: number;
  errorCode?: string;
  createdAt: string;
}

export interface YohPalVideoAggregate {
  videoId: string;
  impressions: number;
  plays: number;
  skips: number;
  completions: number;
  replays: number;
  likes: number;
  comments: number;
  shares: number;
  totalStartupMs: number;
  startupSamples: number;
  totalBufferingMs: number;
  bufferingSamples: number;
}
