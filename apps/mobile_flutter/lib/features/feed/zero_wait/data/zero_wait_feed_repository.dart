import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/firebase.dart' as fb;
import '../models/preload_video.dart';

final class FeedPage {
  const FeedPage({
    required this.videos,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<PreloadVideo> videos;

  /// Opaque cursor for the next [ZeroWaitFeedRepository.fetchPage] call.
  /// `null` when the collection is exhausted.
  final String? nextCursor;
  final bool hasMore;
}

abstract interface class ZeroWaitFeedRepository {
  /// Fetches [limit] videos starting after [cursor].
  /// Pass `cursor: null` to start from the beginning.
  Future<FeedPage> fetchPage({required int limit, String? cursor});
}

/// Firestore implementation using `startAfterDocument` cursor pagination.
///
/// The cursor is the Firestore document ID of the last returned document.
/// A single extra document-read is performed per page to resolve the cursor
/// snapshot — this is bounded to one extra read per replenishment cycle.
final class FirestoreZeroWaitFeedRepository implements ZeroWaitFeedRepository {
  FirestoreZeroWaitFeedRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  final FirebaseFirestore? _firestore;

  final Map<String, DocumentSnapshot> _snapshotCache = {};

  @override
  Future<FeedPage> fetchPage({required int limit, String? cursor}) async {
    final fs = _firestore;
    if (fs == null) {
      return const FeedPage(videos: [], nextCursor: null, hasMore: false);
    }

    Query<Map<String, dynamic>> query = fs
        .collection('videos')
        .where('visibility', isEqualTo: 'public')
        .where('playbackReady', isEqualTo: true)
        .where('processingStatus', isEqualTo: 'ready')
        .where('broken', isEqualTo: false)
        .orderBy('engagementScore', descending: true)
        .limit(limit);

    if (cursor != null) {
      final snap = _snapshotCache[cursor] ??
          await fs.collection('videos').doc(cursor).get();
      if (snap.exists) {
        _snapshotCache[cursor] = snap;
        query = query.startAfterDocument(snap);
      }
    }

    final result = await query.get();

    if (result.docs.isNotEmpty) {
      final last = result.docs.last;
      _snapshotCache[last.id] = last;
    }

    final videos = result.docs
        .map((d) => PreloadVideo.fromFirestore({'id': d.id, ...d.data()}))
        .toList();

    final nextCursor =
        result.docs.isNotEmpty ? result.docs.last.id : null;

    return FeedPage(
      videos: videos,
      nextCursor: nextCursor,
      hasMore: result.docs.length == limit,
    );
  }
}