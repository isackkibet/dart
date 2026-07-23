import 'package:flutter/foundation.dart';
import '../services/video_interaction_service.dart';

class VideoInteractionController extends ChangeNotifier {
  final VideoInteractionService service;

  VideoInteractionController({required this.service});

  final Map<String, bool> liked = {};
  final Map<String, bool> bookmarked = {};
  final Set<String> viewed = {};
  final Map<String, int> optimisticLikeDelta = {};
  final Map<String, int> optimisticBookmarkDelta = {};
  String? error;

  Future<void> loadState({
    required String userId,
    required String videoId,
  }) async {
    liked[videoId] =
        await service.isLiked(userId: userId, videoId: videoId);
    bookmarked[videoId] =
        await service.isBookmarked(userId: userId, videoId: videoId);
    notifyListeners();
  }

  Future<void> toggleLike({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {
    final current = liked[videoId] ?? false;
    final next = !current;
    liked[videoId] = next;
    optimisticLikeDelta[videoId] = next ? 1 : -1;
    notifyListeners();
    try {
      if (current) {
        await service.unlikeVideo(userId: userId, videoId: videoId);
      } else {
        await service.likeVideo(
          userId: userId,
          videoId: videoId,
          creatorId: creatorId,
        );
      }
    } catch (e) {
      liked[videoId] = current;
      optimisticLikeDelta.remove(videoId);
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleBookmark({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {
    final current = bookmarked[videoId] ?? false;
    final next = !current;
    bookmarked[videoId] = next;
    optimisticBookmarkDelta[videoId] = next ? 1 : -1;
    notifyListeners();
    try {
      if (current) {
        await service.unbookmarkVideo(userId: userId, videoId: videoId);
      } else {
        await service.bookmarkVideo(
          userId: userId,
          videoId: videoId,
          creatorId: creatorId,
        );
      }
    } catch (e) {
      bookmarked[videoId] = current;
      optimisticBookmarkDelta.remove(videoId);
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> recordViewOnce({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {
    if (viewed.contains(videoId)) return;
    viewed.add(videoId);
    try {
      await service.recordView(
        userId: userId,
        videoId: videoId,
        creatorId: creatorId,
      );
    } catch (_) {
      // Firestore rules may not yet be deployed; view is deduplicated locally
    }
  }

  Future<void> recordShare({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {
    await service.recordShare(
      userId: userId,
      videoId: videoId,
      creatorId: creatorId,
    );
  }

  int effectiveLikeCount({required int baseCount, required String videoId}) {
    return baseCount + (optimisticLikeDelta[videoId] ?? 0);
  }

  int effectiveBookmarkCount({required int baseCount, required String videoId}) {
    return baseCount + (optimisticBookmarkDelta[videoId] ?? 0);
  }
}
