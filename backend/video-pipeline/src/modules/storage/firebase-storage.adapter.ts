import { Injectable } from '@nestjs/common';
import { getStorage } from 'firebase-admin/storage';
import type { File } from '@google-cloud/storage';

const CDN_BASE = 'https://cdn.stream.yohpal.com';

@Injectable()
export class FirebaseStorageAdapter {
  private get bucket() {
    return getStorage().bucket('yohlab.firebasestorage.app');
  }

  async listProductionVideos(prefix = 'videos-hls/') {
    const [files] = await this.bucket.getFiles({ prefix });
    return (files as File[])
      .filter((file) => file.name.endsWith('/master.m3u8'))
      .map((file) => {
        const parts = file.name.split('/').filter(Boolean);
        const id = parts[1] ?? file.name;
        const base = `${CDN_BASE}/videos-hls/${id}`;
        return {
          id,
          hlsMasterUrl: `${base}/master.m3u8`,
          hls360Url: `${base}/playlist_360p.m3u8`,
          hls480Url: `${base}/playlist_480p.m3u8`,
          hls720Url: `${base}/playlist_720p.m3u8`,
          storagePath: file.name,
          source: 'firebase_storage' as const,
        };
      });
  }
}
