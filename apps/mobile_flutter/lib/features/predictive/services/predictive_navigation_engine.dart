import '../models/predicted_destination_model.dart';

class PredictiveNavigationEngine {
  List<PredictedDestinationModel> predict({
    required String currentScreen,
    required Map<String, dynamic> context,
  }) {
    final predictions = <PredictedDestinationModel>[];

    if (currentScreen == 'feed') {
      final creatorId = context['creatorId'];
      final videoId = context['videoId'];
      if (creatorId != null) {
        predictions.add(PredictedDestinationModel(
          type: 'creator_profile',
          id: creatorId as String,
          confidence: 0.72,
        ));
      }
      if (videoId != null) {
        predictions.add(PredictedDestinationModel(
          type: 'next_video',
          id: videoId as String,
          confidence: 0.9,
        ));
      }
      predictions.add(const PredictedDestinationModel(
        type: 'rewards',
        id: 'ads_arena',
        confidence: 0.45,
      ));
    }

    if (currentScreen == 'creator_profile') {
      predictions.add(const PredictedDestinationModel(
        type: 'chat',
        id: 'messages',
        confidence: 0.6,
      ));
    }

    return predictions.where((p) => p.confidence >= 0.4).toList();
  }
}
