import * as admin from 'firebase-admin';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';
import { spawn } from 'child_process';
import ffmpegPath from '@ffmpeg-installer/ffmpeg';

const bucket = admin.storage().bucket();

export async function extractThumbnailFromVideo(params: {
  videoPath: string;
  outputPath: string;
}): Promise<string> {
  const inputFile = path.join(os.tmpdir(), `input-${Date.now()}.mp4`);
  const outputFile = path.join(os.tmpdir(), `thumb-${Date.now()}.jpg`);

  await bucket.file(params.videoPath).download({ destination: inputFile });

  await new Promise<void>((resolve, reject) => {
    const ffmpeg = spawn(ffmpegPath.path, [
      '-y', '-ss', '0', '-i', inputFile,
      '-frames:v', '1', '-q:v', '2', outputFile,
    ]);
    ffmpeg.on('error', reject);
    ffmpeg.on('close', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`FFmpeg thumbnail extraction failed: ${code}`));
    });
  });

  await bucket.upload(outputFile, {
    destination: params.outputPath,
    metadata: {
      contentType: 'image/jpeg',
      cacheControl: 'public,max-age=31536000,immutable',
    },
  });

  fs.unlinkSync(inputFile);
  fs.unlinkSync(outputFile);

  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(
    params.outputPath,
  )}?alt=media`;
}
