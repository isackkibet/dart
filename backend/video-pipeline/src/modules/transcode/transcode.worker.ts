import { Injectable } from '@nestjs/common';
import path from 'path';
import { FfmpegService } from './ffmpeg.service';
import { YohPalHlsService } from './hls.service';
import { StorageService } from '../storage/storage.service';
import { YohPalVideoEntity } from '../database/video.entity';
import { config } from '../../config';

@Injectable()
export class TranscodeWorker {
  constructor(
    private readonly ffmpeg: FfmpegService,
    private readonly hls: YohPalHlsService,
    private readonly storage: StorageService,
  ) {}

  async process(video: YohPalVideoEntity): Promise<void> {
    video.status = 'TRANSCODING';
    video.updatedAt = new Date();

    const outputDir = path.join(config.outputDir, video.creatorId, video.id);
    const hlsOutputDir = path.join(outputDir, 'hls');
    const inputPath = await this.storage.download(video.originalUrl);

    await this.ffmpeg.generateFastStartMp4(inputPath, outputDir);

    const base = `videos/${video.creatorId}/${video.id}`;
    video.low360Url = await this.storage.store(
      path.join(outputDir, '360p.mp4'), `${base}/360p.mp4`);
    video.medium480Url = await this.storage.store(
      path.join(outputDir, '480p.mp4'), `${base}/480p.mp4`);
    video.high720Url = await this.storage.store(
      path.join(outputDir, '720p.mp4'), `${base}/720p.mp4`);
    video.mp4Ready = true;

    const cdnBase = `https://cdn.stream.yohpal.com/videos-hls/${video.id}`;
    await this.hls.generateHls(inputPath, hlsOutputDir, cdnBase);
    await this.storage.storeDirectory(hlsOutputDir, `videos-hls/${video.id}`);
    video.hlsMasterUrl  = `${cdnBase}/master.m3u8`;
    video.hls360Url     = `${cdnBase}/playlist_360p.m3u8`;
    video.hls480Url     = `${cdnBase}/playlist_480p.m3u8`;
    video.hls720Url     = `${cdnBase}/playlist_720p.m3u8`;
    video.hlsReady = true;

    video.status = 'READY';
    video.updatedAt = new Date();
  }
}
