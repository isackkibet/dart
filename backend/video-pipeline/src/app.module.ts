import { Module } from '@nestjs/common';
import { UploadController } from './modules/upload/upload.controller';
import { UploadService } from './modules/upload/upload.service';
import { TranscodeQueue } from './modules/transcode/transcode.queue';
import { TranscodeWorker } from './modules/transcode/transcode.worker';
import { FfmpegService } from './modules/transcode/ffmpeg.service';
import { StorageService } from './modules/storage/storage.service';
import { SignedUrlService } from './modules/storage/signed-url.service';
import { VideoFeedController } from './modules/feed/video-feed.controller';
import { VideoFeedService } from './modules/feed/video-feed.service';
import { YohPalFeedRankingService } from './modules/feed/feed-ranking.service';
import { YohPalPreloadIntelligenceService } from './modules/feed/preload-intelligence.service';
import { YohPalDeliveryDecisionService } from './modules/feed/delivery-decision.service';
import { YohPalCdnAvailabilityService } from './modules/feed/cdn-availability.service';
import { YohPalHlsService } from './modules/transcode/hls.service';
import { FirebaseStorageAdapter } from './modules/storage/firebase-storage.adapter';
import { FirebaseAdminService } from './modules/database/firebase-admin.service';

@Module({
  controllers: [UploadController, VideoFeedController],
  providers: [
    UploadService,
    TranscodeQueue,
    TranscodeWorker,
    FfmpegService,
    StorageService,
    SignedUrlService,
    VideoFeedService,
    YohPalFeedRankingService,
    YohPalPreloadIntelligenceService,
    YohPalDeliveryDecisionService,
    YohPalCdnAvailabilityService,
    YohPalHlsService,
    FirebaseStorageAdapter,
    FirebaseAdminService,
  ],
})
export class AppModule {}
