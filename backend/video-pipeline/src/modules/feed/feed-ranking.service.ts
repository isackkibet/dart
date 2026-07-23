import { Injectable } from '@nestjs/common';

export interface RankingInput {
  creatorScore: number;
  completionRate: number;
  replayRate: number;
  likeRate: number;
  commentRate: number;
  shareRate: number;
  reportPenalty: number;
  freshnessBoost: number;
}

@Injectable()
export class YohPalFeedRankingService {
  scoreVideo(input: RankingInput): number {
    const engagement =
      input.completionRate * 0.35 +
      input.replayRate * 0.15 +
      input.likeRate * 0.15 +
      input.commentRate * 0.10 +
      input.shareRate * 0.15;

    const trust =
      input.creatorScore * 0.10 -
      input.reportPenalty * 0.30;

    return engagement + trust + input.freshnessBoost;
  }
}
