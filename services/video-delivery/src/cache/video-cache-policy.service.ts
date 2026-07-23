export type VideoCacheContentType =
  | 'mp4-segment'
  | 'hls-manifest'
  | 'hls-segment'
  | 'thumbnail';

export interface VideoCachePolicy {
  ttlSeconds: number;
  staleWhileRevalidateSeconds: number;
  cacheControl: string;
}

export class VideoCachePolicyService {
  getPolicy(contentType: VideoCacheContentType): VideoCachePolicy {
    switch (contentType) {
      case 'mp4-segment':
        return {
          ttlSeconds: 86400,
          staleWhileRevalidateSeconds: 3600,
          cacheControl: 'public, max-age=86400, stale-while-revalidate=3600',
        };
      case 'hls-manifest':
        return {
          ttlSeconds: 3600,
          staleWhileRevalidateSeconds: 300,
          cacheControl: 'public, max-age=3600, stale-while-revalidate=300',
        };
      case 'hls-segment':
        return {
          ttlSeconds: 86400,
          staleWhileRevalidateSeconds: 3600,
          cacheControl: 'public, max-age=86400, stale-while-revalidate=3600',
        };
      case 'thumbnail':
        return {
          ttlSeconds: 604800,
          staleWhileRevalidateSeconds: 86400,
          cacheControl: 'public, max-age=604800, stale-while-revalidate=86400',
        };
    }
  }
}
