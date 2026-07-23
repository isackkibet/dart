import { Injectable } from '@nestjs/common';
import { YohPalVideoEntity } from '../database/video.entity';
import { TranscodeWorker } from './transcode.worker';

@Injectable()
export class TranscodeQueue {
  private readonly queue: YohPalVideoEntity[] = [];
  private processing = false;

  constructor(private readonly worker: TranscodeWorker) {}

  async enqueue(video: YohPalVideoEntity): Promise<void> {
    this.queue.push(video);
    if (!this.processing) {
      void this.processNext();
    }
  }

  private async processNext(): Promise<void> {
    if (this.queue.length === 0) {
      this.processing = false;
      return;
    }
    this.processing = true;
    const video = this.queue.shift()!;
    try {
      await this.worker.process(video);
    } catch {
      video.status = 'FAILED';
      video.updatedAt = new Date();
    }
    void this.processNext();
  }
}
