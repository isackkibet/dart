import 'package:flutter/widgets.dart';

class PredictiveAssetCache {
  Future<void> preloadImageUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await precacheImage(NetworkImage(url), context);
    } catch (_) {
      // Non-blocking predictive cache.
    }
  }

  Future<void> preloadDestinationAssets({
    required BuildContext context,
    required Map<String, dynamic> metadata,
  }) async {
    final urls = [
      metadata['avatarUrl'] as String?,
      metadata['thumbnailUrl'] as String?,
      metadata['profileHeaderUrl'] as String?,
    ].whereType<String>().where((u) => u.isNotEmpty).toList();

    for (final url in urls) {
      if (!context.mounted) return;
      await preloadImageUrl(context, url);
    }
  }
}
