import { Injectable } from '@nestjs/common';
import { YohPalVideoAggregate } from '../telemetry/telemetry.entity';

@Injectable()
export class RankingRefreshService {
  calculateVideoWeight(aggregate: YohPalVideoAggregate): number {
    const plays = aggregate.plays;

    const completionRate = plays === 0 ? 0 : aggregate.completions / plays;
    const skipRate       = plays === 0 ? 0 : aggregate.skips / plays;
    const likeRate       = plays === 0 ? 0 : aggregate.likes / plays;
    const commentRate    = plays === 0 ? 0 : aggregate.comments / plays;
    const shareRate      = plays === 0 ? 0 : aggregate.shares / plays;
    const replayRate     = plays === 0 ? 0 : aggregate.replays / plays;

    const avgStartupMs =
      aggregate.startupSamples === 0
        ? 0
        : aggregate.totalStartupMs / aggregate.startupSamples;

    const avgBufferingMs =
      aggregate.bufferingSamples === 0
        ? 0
        : aggregate.totalBufferingMs / aggregate.bufferingSamples;

    const performancePenalty =
      avgStartupMs > 1500 || avgBufferingMs > 1000 ? 0.20 : 0;

    return (
      completionRate * 0.35 +
      replayRate     * 0.15 +
      likeRate       * 0.15 +
      commentRate    * 0.10 +
      shareRate      * 0.15 -
      skipRate       * 0.20 -
      performancePenalty
    );
  }
}
