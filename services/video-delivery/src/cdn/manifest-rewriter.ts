const CDN_BASE = 'https://cdn.stream.yohpal.com';
const STORAGE_ORIGIN = 'https://firebasestorage.googleapis.com';

export class ManifestRewriter {
  static rewriteToCdn(content: string, videoId: string): string {
    const lines = content.split('\n').map((line) => {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) return line;

      // Already a CDN URL — no change
      if (trimmed.startsWith(CDN_BASE)) return line;

      // Firebase Storage absolute URL — rewrite to CDN
      if (trimmed.startsWith(STORAGE_ORIGIN)) {
        const fileName = ManifestRewriter.extractFileName(trimmed);
        return `${CDN_BASE}/videos-hls/${videoId}/${fileName}`;
      }

      // Relative reference — convert directly
      return `${CDN_BASE}/videos-hls/${videoId}/${trimmed}`;
    });

    const rewritten = lines.join('\n');

    if (rewritten.includes(STORAGE_ORIGIN)) {
      throw new Error(
        `ManifestRewriter: firebasestorage.googleapis.com still present after rewrite for videoId=${videoId}`,
      );
    }

    return rewritten;
  }

  private static extractFileName(storageUrl: string): string {
    // .../o/videos-hls%2F{videoId}%2F{fileName}?alt=media
    const match = storageUrl.match(/\/o\/([^?]+)/);
    if (!match) return storageUrl;
    const decoded = decodeURIComponent(match[1]);
    const parts = decoded.split('/');
    return parts[parts.length - 1];
  }
}
