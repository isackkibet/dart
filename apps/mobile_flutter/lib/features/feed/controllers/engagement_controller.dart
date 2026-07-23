import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/engagement_repository.dart';
import '../domain/engagement_counts.dart';

final class EngagementController extends ChangeNotifier {
  EngagementController({
    required EngagementRepository repository,
    required String videoId,
    required EngagementCounts initial,
    Uuid uuid = const Uuid(),
  })  : _repository = repository,
        _videoId = videoId,
        _counts = initial,
        _uuid = uuid {
    _subscription = _repository.watch(videoId).listen((serverCounts) {
      _counts = serverCounts;
      notifyListeners();
    });
  }

  final EngagementRepository _repository;
  final String _videoId;
  final Uuid _uuid;

  EngagementCounts _counts;
  EngagementCounts get counts => _counts;

  StreamSubscription<EngagementCounts>? _subscription;
  bool _likeMutationInProgress = false;
  bool _saveMutationInProgress = false;

  Future<void> toggleLike() async {
    if (_likeMutationInProgress) return;
    _likeMutationInProgress = true;

    final previous = _counts;
    final liked = !previous.viewerHasLiked;
    _counts = previous.copyWith(
      viewerHasLiked: liked,
      likes: previous.likes + (liked ? 1 : -1),
    );
    notifyListeners();

    try {
      _counts = await _repository.setLike(
        videoId: _videoId,
        liked: liked,
        mutationId: _uuid.v4(),
      );
    } catch (_) {
      _counts = previous;
    } finally {
      _likeMutationInProgress = false;
      notifyListeners();
    }
  }

  Future<void> toggleSave() async {
    if (_saveMutationInProgress) return;
    _saveMutationInProgress = true;

    final previous = _counts;
    final saved = !previous.viewerHasSaved;
    _counts = previous.copyWith(
      viewerHasSaved: saved,
      saves: previous.saves + (saved ? 1 : -1),
    );
    notifyListeners();

    try {
      _counts = await _repository.setSaved(
        videoId: _videoId,
        saved: saved,
        mutationId: _uuid.v4(),
      );
    } catch (_) {
      _counts = previous;
    } finally {
      _saveMutationInProgress = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
