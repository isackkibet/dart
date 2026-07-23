import '../domain/engagement_counts.dart';

abstract interface class EngagementRepository {
  Stream<EngagementCounts> watch(String videoId);

  Future<EngagementCounts> setLike({
    required String videoId,
    required bool liked,
    required String mutationId,
  });

  Future<EngagementCounts> setSaved({
    required String videoId,
    required bool saved,
    required String mutationId,
  });

  Future<void> registerView({
    required String videoId,
    required String viewSessionId,
    required int watchedMilliseconds,
  });

  Future<void> registerShare({
    required String videoId,
    required String mutationId,
    required String channel,
  });
}
