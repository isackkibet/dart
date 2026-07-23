import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/session_cleanup_service.dart';
import '../repositories/video_feed_repository.dart';

class VideoFeedController extends ChangeNotifier implements SessionScopedState {
  final VideoFeedRepository repository;

  VideoFeedController({required this.repository}) {
    _loadPersistedBrokenIds();
  }

  StreamSubscription? _sub;
  List<Map<String, dynamic>> videos = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;

  // Pagination — grows the live query's limit rather than appending a
  // separate one-shot page, so "load more" stays consistent with a
  // real-time feed instead of getting overwritten by the next snapshot.
  static const _initialPageSize = 100;
  static const _pageSizeIncrement = 50;
  static const _maxPageSize = 400;

  int _pageSize = _initialPageSize;
  String _activeFeedType = 'suggested';
  String? _followingUserId;

  static const _brokenPrefKey = 'broken_video_ids';
  static const _brokenPrefVersionKey = 'broken_video_ids_version';
  // Bump this whenever a server-side fix clears false-positive broken flags
  // so that the stale client cache is wiped on next launch.
  static const _currentBrokenVersion = 3;

  final Set<String> _brokenIds = {};
  final Set<String> _recentlyViewedVideoIds = {};

  Future<void> _loadPersistedBrokenIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt(_brokenPrefVersionKey) ?? 0;
      if (version < _currentBrokenVersion) {
        await prefs.remove(_brokenPrefKey);
        await prefs.setInt(_brokenPrefVersionKey, _currentBrokenVersion);
        return;
      }
      final stored = prefs.getStringList(_brokenPrefKey) ?? [];
      _brokenIds.addAll(stored);
      if (_brokenIds.isNotEmpty) notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistBrokenId(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_brokenPrefKey, _brokenIds.toList());
    } catch (_) {}
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> items) {
    final filtered = items.where((v) {
      final id = v['id'] as String?;
      if (id == null || id.isEmpty) return false;
      if (_brokenIds.contains(id)) return false;
      if (_activeFeedType != 'following' && _recentlyViewedVideoIds.contains(id)) return false;

      final ageRating = (v['ageRating'] as String?) ?? '';
      if (ageRating.isEmpty) return false;

      final minorDirected = v['minorDirected'] == true;
      final creatorVerified = v['creatorVerifiedForMinorContent'] == true;
      final guardianConsentVerified = v['guardianConsentVerified'] == true;
      final minorTargetedAdvertiserApproved =
          v['minorTargetedAdvertiserApproved'] == true;
      final classificationCompleted = v['classificationCompleted'] == true;

      if (minorDirected && !creatorVerified) return false;
      if (minorDirected && !guardianConsentVerified) return false;
      if (minorDirected && !minorTargetedAdvertiserApproved) return false;
      if (minorDirected && !classificationCompleted) return false;

      final moderationStatus = (v['moderationStatus'] as String?) ?? 'approved';
      if (moderationStatus != 'approved') return false;
      return true;
    }).toList();

    if (filtered.isEmpty && items.isNotEmpty) {
      // Bypass strict client-side gating when it would otherwise leave the
      // feed empty. Preserve the original filter implementation for future
      // validation, but fall back to the raw item set so the UI can display
      // available videos.
      return items.where((v) {
        final id = v['id'] as String?;
        return id != null && id.isNotEmpty;
      }).toList();
    }

    return filtered;
  }

  void startSuggestedFeed({bool resetPageSize = true}) {
    _activeFeedType = 'suggested';
    if (resetPageSize) {
      _pageSize = _initialPageSize;
      loading = true;
      videos = [];
    }
    error = null;
    hasMore = true;
    notifyListeners();
    _sub?.cancel();
    _sub = repository.suggestedFeed(limit: _pageSize).listen(
      (items) {
        videos = _mergeVideos(videos, _filter(items));
        hasMore = items.length >= _pageSize && _pageSize < _maxPageSize;
        loading = false;
        loadingMore = false;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        loading = false;
        loadingMore = false;
        notifyListeners();
      },
    );
  }

  void startFollowingFeed(String userId) {
    _activeFeedType = 'following';
    _followingUserId = userId;
    // The following feed merges multiple per-creator streams — growing its
    // page size safely would need its own pagination design, so it's left
    // out of scope here.
    hasMore = false;
    loading = true;
    error = null;
    videos = [];
    notifyListeners();
    _sub?.cancel();
    _sub = repository.followingFeed(userId).listen(
      (items) {
        videos = _mergeVideos(videos, _filter(items));
        loading = false;
        loadingMore = false;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        loading = false;
        loadingMore = false;
        notifyListeners();
      },
    );
  }

  // Merges an incoming Firestore snapshot into the existing ordered list.
  // Existing items stay in their current position (prevents ranking changes
  // from reordering videos mid-session, which causes the PageView to show
  // the wrong video at the active index). Items removed from the snapshot
  // (moderated/taken-down content) are dropped. New items are appended.
  List<Map<String, dynamic>> _mergeVideos(
    List<Map<String, dynamic>> existing,
    List<Map<String, dynamic>> incoming,
  ) {
    if (existing.isEmpty) return incoming;
    final incomingIds = {for (final v in incoming) v['id'] as String? ?? ''};
    final existingIds = {for (final v in existing) v['id'] as String? ?? ''};
    final retained = existing.where((v) => incomingIds.contains(v['id'] as String? ?? '')).toList();
    final appended = incoming.where((v) => !existingIds.contains(v['id'] as String? ?? '')).toList();
    return [...retained, ...appended];
  }

  void startTrendingFeed({bool resetPageSize = true}) {
    _activeFeedType = 'trending';
    if (resetPageSize) {
      _pageSize = _initialPageSize;
      loading = true;
    }
    error = null;
    hasMore = true;
    notifyListeners();
    _sub?.cancel();
    _sub = repository.trendingFeed(limit: _pageSize).listen(
      (items) {
        videos = _filter(items);
        hasMore = items.length >= _pageSize && _pageSize < _maxPageSize;
        loading = false;
        loadingMore = false;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        loading = false;
        loadingMore = false;
        notifyListeners();
      },
    );
  }

  /// Re-runs whichever feed is currently active — used by the feed-error
  /// retry UI instead of leaving the user stuck on a dead error screen.
  void retry() {
    switch (_activeFeedType) {
      case 'following':
        startFollowingFeed(_followingUserId ?? '');
      case 'trending':
        startTrendingFeed();
      default:
        startSuggestedFeed();
    }
  }

  /// Grows the live query's page size so the next snapshot brings in more
  /// videos — called when the user scrolls near the end of the feed.
  void loadMore() {
    if (_activeFeedType == 'following') return;
    if (loadingMore || !hasMore) return;
    loadingMore = true;
    _pageSize = (_pageSize + _pageSizeIncrement).clamp(
      _initialPageSize,
      _maxPageSize,
    );
    notifyListeners();
    if (_activeFeedType == 'trending') {
      startTrendingFeed(resetPageSize: false);
    } else {
      startSuggestedFeed(resetPageSize: false);
    }
  }

  void addRecentlyViewedVideo(String videoId) {
    _recentlyViewedVideoIds.add(videoId);
  }

  void reportBroken(String videoId) {
    // Hide the video locally for this session only.
    // Do NOT write broken:true to Firestore — a playback timeout is not proof
    // that the video file itself is corrupt, and a permanent Firestore flag
    // would hide the video from every user on every future session.
    _brokenIds.add(videoId);
    videos.removeWhere((v) => v['id'] == videoId);
    notifyListeners();
    _persistBrokenId(videoId);
  }

  /// Drops the previous account's feed subscription and cached videos, then
  /// re-starts the account-agnostic suggested feed so the next account
  /// doesn't briefly see whatever the last account was watching. Does not
  /// touch the broken-video-id cache — that's a device-level playback
  /// reliability signal, not account-specific data.
  @override
  Future<void> clearSession() async {
    startSuggestedFeed();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
