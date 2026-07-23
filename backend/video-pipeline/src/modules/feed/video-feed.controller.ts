import { Controller, Get, Query } from '@nestjs/common';
import { VideoFeedService } from './video-feed.service';

@Controller('video-feed')
export class VideoFeedController {
  constructor(private readonly feedService: VideoFeedService) {}

  @Get()
  async getFeed(
    @Query('userId') userId?: string,
    @Query('networkType') networkType?: string,
    @Query('lowDataMode') lowDataMode?: string,
  ) {
    return this.feedService.getSmartFeed(
      userId ?? 'default',
      networkType as 'wifi' | '5g' | '4g' | '3g' | '2g' | 'unknown' | undefined,
      lowDataMode === 'true',
    );
  }
}
