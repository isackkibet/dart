import 'package:flutter/foundation.dart';
import '../data/feed_repository.dart';
import '../data/video_exposure_repository.dart';
import '../domain/feed_category.dart';
import '../domain/feed_request.dart';
import '../domain/feed_video.dart';

final class FeedController extends ChangeNotifier {
  FeedController({
    required FeedRepository feedRepository,
    required VideoExposureRepository exposureRepository,
  })  : _feedRepository = feedRepository,
        _exposureRepository = exposureRepository;

  final FeedRepository _feedRepository;
  final VideoExposureRepository _exposureRepository;

  final List<FeedVideo> _videos = [];
  List<FeedVideo> get videos => List.unmodifiable(_videos);

  FeedCategory _category = FeedCategory.recommended;
  FeedCategory get category => _category;

  String? _cursor;
  bool _loading = false;
  bool get loading => _loading;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  Object? _error;
  Object? get error => _error;

  Future<void> selectCategory(FeedCategory category) async {
    if (_category == category && _videos.isNotEmpty) {
      return;
    }
    _category = category;
    _videos.clear();
    _cursor = null;
    _hasMore = true;
    _error = null;
    notifyListeners();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final excluded = await _exposureRepository.loadAutomaticFeedExclusions(
        category: _category,
      );
      final result = await _feedRepository.loadFeed(
        FeedRequest(
          category: _category,
          cursor: _cursor,
          limit: 30,
          excludedVideoIds: excluded,
        ),
      );
      final existingIds = _videos.map((v) => v.id).toSet();
      _videos.addAll(
        result.videos.where((v) => !existingIds.contains(v.id)),
      );
      _cursor = result.nextCursor;
      _hasMore = result.hasMore;
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    _error = null;
    if (_videos.isEmpty) _hasMore = true;
    await loadMore();
  }
}
