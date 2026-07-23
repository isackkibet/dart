export interface CdnDeliveryRequest {
  storagePath: string;
  creatorId: string;
  videoId: string;
  quality: '360p' | '480p' | '720p' | 'hls';
  expiresInSeconds: number;
}

export interface CdnDeliveryResponse {
  url: string;
  provider: string;
  edgeEnabled: boolean;
  cacheTtlSeconds: number;
  headers: Record<string, string>;
}

export interface CdnProvider {
  readonly name: string;
  isAvailable(): Promise<boolean>;
  sign(request: CdnDeliveryRequest): Promise<CdnDeliveryResponse>;
  purge?(videoId: string): Promise<void>;
}
