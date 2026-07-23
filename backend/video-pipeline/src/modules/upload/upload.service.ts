import { Injectable } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { StorageService } from '../storage/storage.service';
import { TranscodeQueue } from '../transcode/transcode.queue';
import { YohPalVideoEntity } from '../database/video.entity';

@Injectable()
export class UploadService {
  private readonly videos = new Map<string, YohPalVideoEntity>();

  constructor(
    private readonly storage: StorageService,
    private readonly transcodeQueue: TranscodeQueue,
  ) {}

  async handleUpload(
    file: Express.Multer.File,
    creatorId: string,
  ): Promise<YohPalVideoEntity> {
    const videoId = uuidv4();
    const storagePath = `videos/${creatorId}/${videoId}/original.mp4`;

    await this.storage.store(file.path, storagePath);

    const entity: YohPalVideoEntity = {
      id: videoId,
      creatorId,
      originalUrl: storagePath,
      status: 'UPLOADED',
      hlsReady: false,
      mp4Ready: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    this.videos.set(videoId, entity);
    await this.transcodeQueue.enqueue(entity);
    return entity;
  }

  findAll(): YohPalVideoEntity[] {
    return Array.from(this.videos.values());
  }

  findReady(): YohPalVideoEntity[] {
    return this.findAll().filter((v) => v.status === 'READY');
  }
}
