import { Injectable } from '@nestjs/common';
import { SignedUrlService } from '../storage/signed-url.service';
import { UploadService } from '../upload/upload.service';
import { FirebaseStorageAdapter } from '../storage/firebase-storage.adapter';
import { YohPalVideoEntity } from '../database/video.entity';
import { YohPalFeedRankingService } from './feed-ranking.service';
import { YohPalPreloadIntelligenceService } from './preload-intelligence.service';
import { YohPalDeliveryDecisionService } from './delivery-decision.service';
import { YohPalCdnAvailabilityService } from './cdn-availability.service';

export interface YohPalFeedVideoResponse {
  id: string;
  creatorId: string;
  low360Url: string;
  medium480Url: string;
  high720Url: string;
  hlsMasterUrl?: string;
  hls360Url?: string;
  hls720Url?: string;
  hlsReady: boolean;
  recommendedDelivery: 'mp4' | 'hls';
  recommendedQuality: '360p' | '480p' | '720p' | 'auto';
  preloadPriority: number;
  videoWeight: number;
  predictedWatchProbability: number;
  headers?: Record<string, string>;
}

@Injectable()
export class VideoFeedService {
  constructor(
    private readonly rankingService: YohPalFeedRankingService,
    private readonly preloadService: YohPalPreloadIntelligenceService,
    private readonly deliveryService: YohPalDeliveryDecisionService,
    private readonly cdnAvailability: YohPalCdnAvailabilityService,
    private readonly signedUrlService: SignedUrlService,
    private readonly uploadService: UploadService,
    private readonly storageAdapter: FirebaseStorageAdapter,
  ) {}

  async getReadyVideos(): Promise<YohPalFeedVideoResponse[]> {
    return this.getSmartFeed('default');
  }

  async getSmartFeed(
    _userId: string,
    networkType: 'wifi' | '5g' | '4g' | '3g' | '2g' | 'unknown' = '4g',
    lowDataMode = false,
  ): Promise<YohPalFeedVideoResponse[]> {
    const [videos, cdnAvailable] = await Promise.all([
      this.findReadyVideos(),
      this.cdnAvailability.isAvailable(),
    ]);

    const ranked = videos
      .map((video) => {
        const score = this.rankingService.scoreVideo({
          creatorScore: video.creatorScore ?? 0.5,
          completionRate: video.completionRate ?? 0,
          replayRate: video.replayRate ?? 0,
          likeRate: video.likeRate ?? 0,
          commentRate: video.commentRate ?? 0,
          shareRate: video.shareRate ?? 0,
          reportPenalty: video.reportPenalty ?? 0,
          freshnessBoost: video.freshnessBoost ?? 0,
        });
        return { video, score };
      })
      .sort((a, b) => b.score - a.score);

    return Promise.all(
      ranked.map(async ({ video, score }) => {
        const delivery = this.deliveryService.decide({
          hlsReady: video.hlsReady,
          cdnAvailable,
          networkType,
          lowDataMode,
        });

        return {
          id: video.id,
          creatorId: video.creatorId,
          low360Url: await this.signedUrlService.sign(video.low360Url!),
          medium480Url: await this.signedUrlService.sign(video.medium480Url!),
          high720Url: await this.signedUrlService.sign(video.high720Url!),
          hlsMasterUrl: video.hlsMasterUrl
            ? await this.signedUrlService.sign(video.hlsMasterUrl)
            : undefined,
          hls360Url: video.hls360Url
            ? await this.signedUrlService.sign(video.hls360Url)
            : undefined,
          hls720Url: video.hls720Url
            ? await this.signedUrlService.sign(video.hls720Url)
            : undefined,
          hlsReady: video.hlsReady,
          recommendedDelivery: delivery.recommendedDelivery,
          recommendedQuality: delivery.recommendedQuality,
          preloadPriority: this.preloadService.getPreloadPriority(score),
          videoWeight: score,
          predictedWatchProbability: Math.min(Math.max(score, 0), 1),
          headers: {},
        };
      }),
    );
  }

  private async findReadyVideos(): Promise<YohPalVideoEntity[]> {
    const [inMemory, fromStorage] = await Promise.all([
      this.uploadService.findReady(),
      this.storageAdapter.listProductionVideos().catch(() => []),
    ]);

    const inMemoryIds = new Set(inMemory.map((v) => v.id));

    const storageEntities: YohPalVideoEntity[] = fromStorage
      .filter((v) => !inMemoryIds.has(v.id))
      .map((v) => ({
        id: v.id,
        creatorId: 'production',
        originalUrl: v.hlsMasterUrl,
        hlsMasterUrl: v.hlsMasterUrl,
        hls360Url: v.hls360Url,
        hls480Url: v.hls480Url,
        hls720Url: v.hls720Url,
        low360Url: v.hls360Url,
        medium480Url: v.hls480Url,
        high720Url: v.hls720Url,
        hlsReady: true,
        mp4Ready: false,
        status: 'READY' as const,
        createdAt: new Date(),
        updatedAt: new Date(),
      }));

    return [...inMemory, ...storageEntities];
  }
}
