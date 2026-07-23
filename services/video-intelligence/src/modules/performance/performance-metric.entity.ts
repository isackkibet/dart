export interface YohPalVideoPerformanceMetric {
  id: string;
  videoId?: string;
  deviceId: string;
  userId?: string;
  startupMs: number;
  bufferingMs: number;
  droppedFrames: number;
  scrollFps: number;
  memoryMb: number;
  cacheHit: boolean;
  deliveryProvider: 'origin' | 'cloudflare' | 'bunny' | 'cloudfront' | 'regional';
  deliveryMode: 'mp4' | 'hls';
  playbackError: boolean;
  errorCode?: string;
  testSessionId?: string;
  recordedAt: Date;
}
