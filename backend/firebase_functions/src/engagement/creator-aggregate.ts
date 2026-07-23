export interface CreatorAggregateComparison {
  creatorId: string;
  storedTotalViews: number;
  computedTotalViews: number;
  storedTotalLikes: number;
  computedTotalLikes: number;
}

export function aggregateMatches(
  comparison: CreatorAggregateComparison
): boolean {
  return (
    comparison.storedTotalViews === comparison.computedTotalViews &&
    comparison.storedTotalLikes === comparison.computedTotalLikes
  );
}
