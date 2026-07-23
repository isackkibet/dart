import 'package:flutter/material.dart';
import '../models/predicted_destination_model.dart';
import '../services/predictive_asset_cache.dart';
import '../services/predictive_navigation_engine.dart';
import '../services/adaptive_memory_manager.dart';

class PredictiveExperienceController extends ChangeNotifier {
  final PredictiveNavigationEngine navigationEngine;
  final PredictiveAssetCache assetCache;
  final AdaptiveMemoryManager memoryManager;

  PredictiveExperienceController({
    required this.navigationEngine,
    required this.assetCache,
    required this.memoryManager,
  });

  List<PredictedDestinationModel> predictions = [];

  Future<void> warmPredictedDestinations({
    required BuildContext context,
    required String currentScreen,
    required Map<String, dynamic> screenContext,
    int estimatedRamGb = 4,
  }) async {
    final memoryClass = memoryManager.classify(estimatedRamGb: estimatedRamGb);
    final maxItems = memoryManager.maxPredictivePreloads(memoryClass);

    predictions = navigationEngine
        .predict(currentScreen: currentScreen, context: screenContext)
        .take(maxItems)
        .toList();

    for (final prediction in predictions) {
      await assetCache.preloadDestinationAssets(
        context: context,
        metadata: prediction.metadata,
      );
    }
    notifyListeners();
  }
}
