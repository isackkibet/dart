import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VideoDraft {
  final String localFilePath;
  final String title;
  final String caption;
  final List<String> hashtags;
  final DateTime savedAt;

  const VideoDraft({
    required this.localFilePath,
    required this.title,
    required this.caption,
    required this.hashtags,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'localFilePath': localFilePath,
        'title': title,
        'caption': caption,
        'hashtags': hashtags,
        'savedAt': savedAt.toIso8601String(),
      };

  factory VideoDraft.fromJson(Map<String, dynamic> json) => VideoDraft(
        localFilePath: json['localFilePath'] as String,
        title: json['title'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        hashtags: List<String>.from(json['hashtags'] ?? const []),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}

/// Persists a single in-progress video draft (recorded/picked file + form
/// fields) so a creator who backs out mid-flow doesn't lose their work.
class VideoDraftService {
  static const _key = 'yohpal_video_upload_draft';

  Future<void> save(VideoDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(draft.toJson()));
  }

  Future<VideoDraft?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return VideoDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
