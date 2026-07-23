import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/predictive/models/predicted_destination_model.dart';
import 'package:yohpal_live_v2/features/predictive/services/predictive_navigation_engine.dart';
import 'package:yohpal_live_v2/features/predictive/services/adaptive_memory_manager.dart';

void main() {
  group('Phase 1P — Predictive Experience Engine', () {
    final engine = PredictiveNavigationEngine();
    final memoryManager = AdaptiveMemoryManager();

    test('feed screen predicts creator_profile when creatorId present', () {
      final results = engine.predict(
        currentScreen: 'feed',
        context: {'creatorId': 'creator_abc', 'videoId': 'video_123'},
      );
      expect(results.any((p) => p.type == 'creator_profile'), isTrue);
      expect(
        results.firstWhere((p) => p.type == 'creator_profile').id,
        'creator_abc',
      );
    });

    test('feed screen predicts next_video with confidence 0.9', () {
      final results = engine.predict(
        currentScreen: 'feed',
        context: {'videoId': 'video_123'},
      );
      final nextVideo = results.firstWhere((p) => p.type == 'next_video');
      expect(nextVideo.confidence, 0.9);
    });

    test('feed screen always includes rewards prediction', () {
      final results = engine.predict(
        currentScreen: 'feed',
        context: {},
      );
      expect(results.any((p) => p.type == 'rewards'), isTrue);
    });

    test('creator_profile screen predicts chat', () {
      final results = engine.predict(
        currentScreen: 'creator_profile',
        context: {},
      );
      expect(results.any((p) => p.type == 'chat'), isTrue);
    });

    test('predictions below 0.4 confidence are filtered out', () {
      final results = engine.predict(
        currentScreen: 'feed',
        context: {},
      );
      expect(results.every((p) => p.confidence >= 0.4), isTrue);
    });

    test('AdaptiveMemoryManager classifies RAM correctly', () {
      expect(
        memoryManager.classify(estimatedRamGb: 2),
        DeviceMemoryClass.low,
      );
      expect(
        memoryManager.classify(estimatedRamGb: 4),
        DeviceMemoryClass.medium,
      );
      expect(
        memoryManager.classify(estimatedRamGb: 8),
        DeviceMemoryClass.high,
      );
    });

    test('AdaptiveMemoryManager returns correct preload limits', () {
      expect(memoryManager.maxPredictivePreloads(DeviceMemoryClass.low), 2);
      expect(memoryManager.maxPredictivePreloads(DeviceMemoryClass.medium), 4);
      expect(memoryManager.maxPredictivePreloads(DeviceMemoryClass.high), 8);
    });

    test('PredictedDestinationModel holds all fields', () {
      const model = PredictedDestinationModel(
        type: 'creator_profile',
        id: 'creator_abc',
        confidence: 0.72,
        metadata: {'avatarUrl': 'https://example.com/avatar.jpg'},
      );
      expect(model.type, 'creator_profile');
      expect(model.id, 'creator_abc');
      expect(model.confidence, 0.72);
      expect(model.metadata['avatarUrl'], 'https://example.com/avatar.jpg');
    });
  });
}
