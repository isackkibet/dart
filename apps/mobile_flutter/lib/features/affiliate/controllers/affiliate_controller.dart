import 'package:flutter/foundation.dart';
import '../services/affiliate_service.dart';

class AffiliateController extends ChangeNotifier {
  final AffiliateService service;

  AffiliateController({required this.service});

  bool loading = false;
  String? error;
  String? latestLink;

  Future<void> generateGeneralLink(String userId) async {
    await _run(() async {
      latestLink = await service.createGeneralLink(userId);
    });
  }

  Future<void> generateVideoLink({
    required String userId,
    required String videoId,
  }) async {
    await _run(() async {
      latestLink = await service.createVideoLink(
        userId: userId,
        videoId: videoId,
      );
    });
  }

  Future<void> generateCreatorLink({
    required String userId,
    required String creatorId,
  }) async {
    await _run(() async {
      latestLink = await service.createCreatorLink(
        userId: userId,
        creatorId: creatorId,
      );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
