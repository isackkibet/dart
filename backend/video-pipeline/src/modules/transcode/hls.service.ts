import { Injectable } from '@nestjs/common';
import { execFile } from 'child_process';
import fs from 'fs/promises';
import path from 'path';

export const HLS_OUTPUTS = {
  master:  'master.m3u8',
  low360:  'playlist_360p.m3u8',
  mid480:  'playlist_480p.m3u8',
  high720: 'playlist_720p.m3u8',
};

export function buildMasterManifest(baseUrl: string): string {
  return [
    '#EXTM3U',
    '#EXT-X-VERSION:3',
    '',
    '#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360',
    `${baseUrl}/${HLS_OUTPUTS.low360}`,
    '',
    '#EXT-X-STREAM-INF:BANDWIDTH=1200000,RESOLUTION=854x480',
    `${baseUrl}/${HLS_OUTPUTS.mid480}`,
    '',
    '#EXT-X-STREAM-INF:BANDWIDTH=2500000,RESOLUTION=1280x720',
    `${baseUrl}/${HLS_OUTPUTS.high720}`,
  ].join('\n');
}

@Injectable()
export class YohPalHlsService {
  async generateHls(inputPath: string, outputDir: string, cdnBase?: string): Promise<void> {
    await fs.mkdir(outputDir, { recursive: true });
    await this.generateVariant(inputPath, outputDir, '360p', 640, 360, '800k');
    await this.generateVariant(inputPath, outputDir, '480p', 854, 480, '1200k');
    await this.generateVariant(inputPath, outputDir, '720p', 1280, 720, '2500k');
    await this.writeMasterManifest(outputDir, cdnBase);
  }

  private async generateVariant(
    input: string,
    outputDir: string,
    label: string,
    width: number,
    height: number,
    bitrate: string,
  ): Promise<void> {
    const playlistPath = path.join(outputDir, `playlist_${label}.m3u8`);
    const segmentPath  = path.join(outputDir, `v${label}_%03d.ts`);

    return new Promise((resolve, reject) => {
      execFile(
        'ffmpeg',
        [
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
          '-hls_time', '2',
          '-hls_playlist_type', 'vod',
          '-hls_segment_filename', segmentPath,
          playlistPath,
        ],
        (error) => {
          if (error) reject(error);
          else resolve();
        },
      );
    });
  }

  private async writeMasterManifest(outputDir: string, cdnBase?: string): Promise<void> {
    const base = cdnBase ?? '.';
    const content = buildMasterManifest(base);
    await fs.writeFile(path.join(outputDir, HLS_OUTPUTS.master), content);
  }
}
