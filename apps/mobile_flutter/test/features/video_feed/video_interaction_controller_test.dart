import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/video_feed/controllers/video_interaction_controller.dart';
import 'package:yohpal_live_v2/features/video_feed/models/video_model.dart';
import 'package:yohpal_live_v2/features/video_feed/services/video_interaction_service.dart';

class _FakeVideoInteractionService extends VideoInteractionService {
  int likeCalls = 0;
  int unlikeCalls = 0;
  bool liked = false;

  _FakeVideoInteractionService() : super();

  @override
  Future<bool> isLiked({required String userId, required String videoId}) async {
    return liked;
  }

  @override
  Future<void> likeVideo({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {
    likeCalls += 1;
    liked = true;
  }

  @override
  Future<void> unlikeVideo({required String userId, required String videoId}) async {
    unlikeCalls += 1;
    liked = false;
  }

  @override
  Future<void> bookmarkVideo({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {}

  @override
  Future<void> unbookmarkVideo({required String userId, required String videoId}) async {}

  @override
  Future<void> recordView({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {}

  @override
  Future<void> recordShare({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {}
}

void main() {
  test('optimistic like state increments then decrements the visible count', () async {
    final service = _FakeVideoInteractionService();
    final controller = VideoInteractionController(service: service);
    final video = VideoModel(
      id: 'video-1',
      ownerId: 'creator-1',
      hlsUrl: 'https://example.com/video.mp4',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      caption: 'Test video',
      tags: const ['test'],
    );

    expect(controller.effectiveLikeCount(baseCount: video.likes, videoId: video.id), 0);

    await controller.toggleLike(
      userId: 'user-1',
      videoId: video.id,
      creatorId: video.ownerId,
    );

    expect(controller.effectiveLikeCount(baseCount: 10, videoId: video.id), 11);

    await controller.toggleLike(
      userId: 'user-1',
      videoId: video.id,
      creatorId: video.ownerId,
    );

    expect(controller.effectiveLikeCount(baseCount: 10, videoId: video.id), 10);
  });
}
