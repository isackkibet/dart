import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;

class VideoFeedRepository {
  final FirebaseFirestore? _firestore;

  VideoFeedRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  // Session-scoped cache: userId → display name / handle.
  // Populated once per user per session via _enrichWithUsernames.
  final Map<String, Map<String, dynamic>> _creatorInfoCache = {};

  /// Injects creator identity fields into each video map.
  ///
  /// Uses individual `doc().get()` calls (not `whereIn` queries) so that
  /// Firestore `allow get` rules are satisfied even when `allow list` is
  /// restricted. All lookups run in parallel so total latency ≈ slowest single
  /// doc fetch rather than the sum.
  Future<List<Map<String, dynamic>>> _enrichWithUsernames(
      List<Map<String, dynamic>> videos) async {
    if (videos.isEmpty) return videos;

    final fs = _firestore;
    if (fs == null) return videos;

    final uncached = videos
        .map((v) => (v['userId'] ?? v['ownerId'] ?? '') as String)
        .where((id) => id.isNotEmpty && !_creatorInfoCache.containsKey(id))
        .toSet()
        .toList();

    if (uncached.isNotEmpty) {
      await Future.wait(uncached.map((uid) async {
        try {
          final profileDoc = await fs
              .collection('creatorProfiles')
              .doc(uid)
              .get();
          if (profileDoc.exists) {
            final profileData = profileDoc.data()!;
            final username = _pickName(profileData);
            final displayName = (profileData['displayName'] as String?)?.trim() ?? '';
            final verified = (profileData['status'] as String?) == 'verified';
            if (username.isNotEmpty || displayName.isNotEmpty) {
              _creatorInfoCache[uid] = {
                'ownerUsername': username,
                'ownerDisplayName': displayName,
                'ownerVerified': verified,
              };
              return;
            }
          }
          final userDoc =
              await fs.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final username = _pickName(userData);
            final displayName = (userData['displayName'] as String?)?.trim() ?? '';
            if (username.isNotEmpty || displayName.isNotEmpty) {
              _creatorInfoCache[uid] = {
                'ownerUsername': username,
                'ownerDisplayName': displayName,
                'ownerVerified': false,
              };
            }
          }
        } catch (_) {
          // Never block the feed — identity stays blank, retried on next emission.
        }
      }));
    }

    return videos.map((v) {
      final uid = (v['userId'] ?? v['ownerId'] ?? '') as String;
      final info = _creatorInfoCache[uid];
      if (info == null || info.isEmpty) return v;
      return {
        ...v,
        if ((info['ownerUsername'] as String?)?.isNotEmpty == true)
          'ownerUsername': info['ownerUsername'],
        if ((info['ownerDisplayName'] as String?)?.isNotEmpty == true)
          'ownerDisplayName': info['ownerDisplayName'],
        if (info['ownerVerified'] == true) 'ownerVerified': true,
      };
    }).toList();
  }

  static String _pickName(Map<String, dynamic> d) {
    final userName = (d['userName'] as String?)?.trim() ?? '';
    if (userName.isNotEmpty) return userName;
    final username = (d['username'] as String?)?.trim() ?? '';
    if (username.isNotEmpty) return username;
    return (d['displayName'] as String?)?.trim() ?? '';
  }

  // Must mirror VideoModel.fromMap()'s resolution order so that every video
  // admitted here has at least one URL the model will actually resolve.
  // previewUrl is excluded — VideoModel never reads it for playback.
  static const _urlFields = [
    'previewUrl',
    'hlsLowUrl',
    'hlsStandardUrl',
    'hlsUrl',
    'videoUrl',
  ];

  static bool _isReady(Map<String, dynamic> d) {
    if (d['status'] != 'live') return false;
    if (d['visibility'] == 'private') return false;
    return _urlFields.any((f) {
      final v = d[f];
      return v is String && v.isNotEmpty;
    });
  }

  Future<List<Map<String, dynamic>>> fetchInitialSuggestedVideos({
    int limit = 4,
  }) async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap = await fs
        .collection('videos')
        .where('status', isEqualTo: 'live')
        .orderBy('engagementScore', descending: true)
        .limit(30)
        .get();

    final videos = snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .where(_isReady)
        .take(limit)
        .toList();
    return _enrichWithUsernames(videos);
  }

  Stream<List<Map<String, dynamic>>> suggestedFeed({int limit = 100}) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('videos')
        .where('status', isEqualTo: 'live')
        .orderBy('engagementScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where(_isReady)
            .toList())
        .asyncMap(_enrichWithUsernames);
  }

  Future<List<Map<String, dynamic>>> fetchNextPage({
    required String lastVideoId,
    int limit = 30,
  }) async {
    final fs = _firestore;
    if (fs == null) return [];
    final lastDoc =
        await fs.collection('videos').doc(lastVideoId).get();
    if (!lastDoc.exists) return [];
    final snap = await fs
        .collection('videos')
        .where('status', isEqualTo: 'live')
        .orderBy('engagementScore', descending: true)
        .startAfterDocument(lastDoc)
        .limit(limit)
        .get();
    final videos = snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .where(_isReady)
        .toList();
    return _enrichWithUsernames(videos);
  }

  Stream<List<Map<String, dynamic>>> followingFeed(String userId) async* {
    final fs = _firestore;
    if (fs == null) {
      yield [];
      return;
    }
    final followsSnap = await fs
        .collection('follows')
        .where('followerUid', isEqualTo: userId)
        .get();

    final creatorIds = followsSnap.docs
        .map((d) => d['creatorUid']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (creatorIds.isEmpty) {
      yield [];
      return;
    }

    // Chunk into groups of 30 (Firestore whereIn limit)
    final chunks = <List<String>>[];
    for (int i = 0; i < creatorIds.length; i += 30) {
      chunks.add(creatorIds.sublist(i, (i + 30).clamp(0, creatorIds.length)));
    }

    if (chunks.length == 1) {
      yield* _chunkStream(chunks.first);
      return;
    }

    // Multiple chunks — merge all chunk streams, re-emit on any update
    final controller = StreamController<List<Map<String, dynamic>>>();
    final chunkResults =
        List<List<Map<String, dynamic>>>.filled(chunks.length, const []);
    final subs = <StreamSubscription<List<Map<String, dynamic>>>>[];

    void emit() {
      final merged = chunkResults.expand((r) => r).toList()
        ..sort((a, b) {
          final at =
              (a['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bt =
              (b['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bt.compareTo(at);
        });
      if (!controller.isClosed) controller.add(merged.take(100).toList());
    }

    for (int i = 0; i < chunks.length; i++) {
      final idx = i;
      subs.add(_chunkStream(chunks[idx]).listen((rows) {
        chunkResults[idx] = rows;
        emit();
      }, onError: (Object e) {
        if (!controller.isClosed) controller.addError(e);
      }));
    }

    try {
      yield* controller.stream;
    } finally {
      for (final s in subs) {
        await s.cancel();
      }
      await controller.close();
    }
  }

  Stream<List<Map<String, dynamic>>> _chunkStream(List<String> creatorIds) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    // No 'status' filter here — the (userId, timestamp) composite index only
    // covers userId + timestamp. Adding status would need a new
    // (userId, status, timestamp) index that doesn't exist yet.
    // _isReady handles status filtering client-side.
    return fs
        .collection('videos')
        .where('userId', whereIn: creatorIds)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where(_isReady)
            .toList())
        .asyncMap(_enrichWithUsernames);
  }

  Stream<List<Map<String, dynamic>>> trendingFeed({int limit = 100}) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('videos')
        .where('status', isEqualTo: 'live')
        .orderBy('engagementScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where(_isReady)
            .toList()
          ..sort((a, b) {
            final av = (a['views'] as num? ?? 0);
            final bv = (b['views'] as num? ?? 0);
            return bv.compareTo(av);
          }))
        .asyncMap(_enrichWithUsernames);
  }

  Future<void> markBroken(String videoId) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs.collection('videos').doc(videoId).update({
        'broken': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return;
      rethrow;
    } catch (_) {}
  }
}
