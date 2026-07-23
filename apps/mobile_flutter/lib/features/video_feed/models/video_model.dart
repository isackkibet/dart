import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String ownerId;
  final String ownerUsername;
  final String ownerDisplayName;
  final bool ownerVerified;
  final String hlsUrl;
  final String thumbnailUrl;
  final String caption;
  final List<String> tags;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final int gifts;
  final bool broken;
  final bool flagged;
  final DateTime? createdAt;
  final String ageRating;
  final bool minorDirected;
  final bool creatorVerifiedForMinorContent;
  final bool guardianConsentVerified;
  final bool minorTargetedAdvertiserApproved;
  final bool classificationCompleted;
  final String moderationStatus;
  final bool viewerHasLiked;
  final bool viewerHasSaved;

  VideoModel({
    required this.id,
    required this.ownerId,
    this.ownerUsername = '',
    this.ownerDisplayName = '',
    this.ownerVerified = false,
    required this.hlsUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.tags,
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.gifts = 0,
    this.broken = false,
    this.flagged = false,
    this.createdAt,
    this.ageRating = 'general',
    this.minorDirected = false,
    this.creatorVerifiedForMinorContent = false,
    this.guardianConsentVerified = false,
    this.minorTargetedAdvertiserApproved = false,
    this.classificationCompleted = false,
    this.moderationStatus = 'approved',
    this.viewerHasLiked = false,
    this.viewerHasSaved = false,
  });

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _formatTimestamp(DateTime? createdAt) {
    if (createdAt == null) return 'Just now';
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
    return '${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}';
  }

  static String _monthName(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  factory VideoModel.fromMap(String id, Map<String, dynamic> data) {
    // Resolve the best playable URL. Priority:
    //   1. hlsLowUrl / hlsStandardUrl — actual HLS playlists set by backfill
    //   2. hlsUrl  — may point to raw MP4 in videos-raw/, used as fallback
    //   3. videoUrl — raw MP4 Storage download URL
    //   4. hlsPath  — CDN or Storage HLS URL (set by upload pipeline)
    //   5. Derive from originalUrl/originalPath (bare Storage path → public URL)
    final String rawHlsLow  = (data['hlsLowUrl']      as String?) ?? '';
    final String rawHlsStd  = (data['hlsStandardUrl']  as String?) ?? '';
    final String rawHls     = (data['hlsUrl']           as String?) ?? '';
    final String rawVideo   = (data['videoUrl']         as String?) ?? '';
    final String rawPath    = (data['hlsPath']          as String?) ?? '';
    final String origUrl    = (data['originalUrl'] ?? data['originalPath'] ?? '') as String;

    String resolvedUrl = '';
    if (rawHlsLow.isNotEmpty) {
      resolvedUrl = rawHlsLow;
    } else if (rawHlsStd.isNotEmpty) {
      resolvedUrl = rawHlsStd;
    } else if (rawHls.isNotEmpty) {
      resolvedUrl = rawHls;
    } else if (rawVideo.isNotEmpty) {
      resolvedUrl = rawVideo;
    } else if (rawPath.isNotEmpty) {
      resolvedUrl = rawPath;
    } else if (origUrl.isNotEmpty && !origUrl.startsWith('http')) {
      // Bare Storage path → build public URL (videos-hls/ is publicly readable)
      const bucket = 'yohlab.firebasestorage.app';
      resolvedUrl = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(origUrl)}?alt=media';
    } else if (origUrl.isNotEmpty) {
      resolvedUrl = origUrl;
    }

    return VideoModel(
      id:            id,
      // Real schema uses userId; legacy docs may use ownerId
      ownerId:       (data['ownerId']   as String?)?.isNotEmpty == true
                         ? data['ownerId'] as String
                         : (data['userId'] as String?) ?? '',
      // Real schema uses userName or fullName
      ownerUsername: (data['ownerUsername'] as String?)?.isNotEmpty == true
                         ? data['ownerUsername'] as String
                         : (data['userName'] ?? data['fullName'] ?? '') as String,
      ownerDisplayName: (data['ownerDisplayName'] as String?) ?? '',
      ownerVerified: data['ownerVerified'] == true,
      hlsUrl:        resolvedUrl,
      // Real schema uses thumbnail; legacy uses thumbnailUrl
      thumbnailUrl:  (data['thumbnailUrl'] as String?)?.isNotEmpty == true
                         ? data['thumbnailUrl'] as String
                         : (data['thumbnail'] ?? '') as String,
      caption:       (data['caption'] ?? data['title'] ?? '') as String,
      // Real schema writes hashtags via the manual/AI publish flows;
      // legacy docs may use tags.
      tags:          List<String>.from(data['tags'] ?? data['hashtags'] ?? const []),
      views:         _parseInt(data['viewsCount'] ?? data['views']),
      likes:         _parseInt(data['likesCount'] ?? data['likes']),
      comments:      _parseInt(data['commentsCount'] ?? data['comments'] ?? data['commentCount']),
      shares:        _parseInt(data['sharesCount'] ?? data['shares'] ?? data['shareCount']),
      saves:         _parseInt(data['savesCount'] ?? data['saves'] ?? data['bookmarkCount']),
      gifts:         _parseInt(data['giftsCount'] ?? data['gifts'] ?? data['giftCount']),
      broken:        data['broken'] == true,
      flagged:       data['flagged'] == true,
      createdAt:     _parseDateTime(
        data['createdAt'] ?? data['timestamp'] ?? data['created_at'] ?? data['uploadedAt'],
      ),
      ageRating:     (data['ageRating'] as String?) ?? 'general',
      minorDirected: data['minorDirected'] == true,
      creatorVerifiedForMinorContent: data['creatorVerifiedForMinorContent'] == true,
      guardianConsentVerified: data['guardianConsentVerified'] == true,
      minorTargetedAdvertiserApproved:
          data['minorTargetedAdvertiserApproved'] == true,
      classificationCompleted: data['classificationCompleted'] == true,
      moderationStatus: (data['moderationStatus'] as String?) ?? 'approved',
      viewerHasLiked: data['viewerHasLiked'] == true,
      viewerHasSaved: data['viewerHasSaved'] == true,
    );
  }

  VideoModel copyWith({
    int? views,
    int? likes,
    int? comments,
    int? shares,
    int? saves,
    int? gifts,
    bool? viewerHasLiked,
    bool? viewerHasSaved,
    bool? guardianConsentVerified,
    bool? minorTargetedAdvertiserApproved,
    bool? classificationCompleted,
    String? ownerDisplayName,
    bool? ownerVerified,
  }) {
    return VideoModel(
      id: id,
      ownerId: ownerId,
      ownerUsername: ownerUsername,
      ownerDisplayName: ownerDisplayName ?? this.ownerDisplayName,
      ownerVerified: ownerVerified ?? this.ownerVerified,
      hlsUrl: hlsUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      tags: tags,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      saves: saves ?? this.saves,
      gifts: gifts ?? this.gifts,
      broken: broken,
      flagged: flagged,
      createdAt: createdAt,
      ageRating: ageRating,
      minorDirected: minorDirected,
      creatorVerifiedForMinorContent: creatorVerifiedForMinorContent,
      guardianConsentVerified:
          guardianConsentVerified ?? this.guardianConsentVerified,
      minorTargetedAdvertiserApproved:
          minorTargetedAdvertiserApproved ?? this.minorTargetedAdvertiserApproved,
      classificationCompleted:
          classificationCompleted ?? this.classificationCompleted,
      moderationStatus: moderationStatus,
      viewerHasLiked: viewerHasLiked ?? this.viewerHasLiked,
      viewerHasSaved: viewerHasSaved ?? this.viewerHasSaved,
    );
  }

  String get timestampLabel => _formatTimestamp(createdAt);

  bool get isMinorSafetyRestricted =>
      minorDirected && !creatorVerifiedForMinorContent;

  bool get requiresGuardianConsent => minorDirected && creatorVerifiedForMinorContent;

  bool get isModerationApproved => moderationStatus == 'approved';

  bool get isPlayable => !broken && !flagged && hlsUrl.isNotEmpty;
}
