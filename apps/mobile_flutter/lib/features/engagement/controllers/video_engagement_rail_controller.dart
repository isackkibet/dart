import 'package:flutter/foundation.dart';
import '../repositories/private_engagement_repository.dart';

class VideoEngagementRailController extends ChangeNotifier {
  final PrivateEngagementRepository privateRepository;

  VideoEngagementRailController({required this.privateRepository});

  bool loading = false;
  String? error;

  Future<void> privateLike({
    required String userId,
    required String creatorId,
    required String videoId,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await privateRepository.privateLike(
        userId: userId,
        creatorId: creatorId,
        videoId: videoId,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> privateComment({
    required String userId,
    required String creatorId,
    required String videoId,
    required String text,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await privateRepository.privateComment(
        userId: userId,
        creatorId: creatorId,
        videoId: videoId,
        text: text,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
