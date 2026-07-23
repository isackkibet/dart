import 'package:flutter/foundation.dart';
import '../repositories/follow_repository.dart';

class CreatorProfileController extends ChangeNotifier {
  final FollowRepository followRepository;

  CreatorProfileController({required this.followRepository});

  bool busy = false;
  String? error;

  Future<void> toggleFollow({
    required bool currentlyFollowing,
    required String followerUid,
    required String creatorUid,
  }) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (currentlyFollowing) {
        await followRepository.unfollow(
          followerUid: followerUid,
          creatorUid: creatorUid,
        );
      } else {
        await followRepository.follow(
          followerUid: followerUid,
          creatorUid: creatorUid,
        );
      }
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
