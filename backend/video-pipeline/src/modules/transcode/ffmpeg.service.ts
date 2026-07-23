import { Injectable } from '@nestjs/common';
import { execFile } from 'child_process';
import path from 'path';
import fs from 'fs/promises';

@Injectable()
export class FfmpegService {
  async generateFastStartMp4(inputPath: string, outputDir: string): Promise<void> {
    await fs.mkdir(outputDir, { recursive: true });
    await this.transcode(inputPath, path.join(outputDir, '360p.mp4'), 640, 360, '800k');
    await this.transcode(inputPath, path.join(outputDir, '480p.mp4'), 854, 480, '1200k');
    await this.transcode(inputPath, path.join(outputDir, '720p.mp4'), 1280, 720, '2500k');
  }

  private transcode(
    input: string,
    output: string,
    width: number,
    height: number,
    bitrate: string,
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      execFile('ffmpeg', [
        '-y',
        '-i', input,
        '-vf', `scale=${width}:${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2`,
        '-c:v', 'libx264',
        '-preset', 'veryfast',
        '-profile:v', 'main',
        '-level', '3.1',
        '-b:v', bitrate,
        '-maxrate', bitrate,
        '-bufsize', '2M',
        '-c:a', 'aac',
        '-b:a', '128k',
        '-movflags', '+faststart',
        output,
      ], (error) => {
        if (error) reject(error);
        else resolve();
      });
    });
  }
}
