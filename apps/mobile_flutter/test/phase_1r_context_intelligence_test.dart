import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/context_intelligence/models/context_action_model.dart';
import 'package:yohpal_live_v2/features/context_intelligence/models/context_snapshot_model.dart';
import 'package:yohpal_live_v2/features/context_intelligence/services/context_intelligence_engine.dart';

void main() {
  group('Phase 1R — Context Intelligence Engine', () {
    late ContextIntelligenceEngine engine;

    setUp(() {
      engine = ContextIntelligenceEngine();
    });

    test('always includes Ask AI action on feed screen with videoId', () {
      final snapshot = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'v123',
        creatorId: 'c1',
      );
      final actions = engine.evaluate(snapshot);
      expect(actions.any((a) => a.type == 'ai_video_companion'), isTrue);
    });

    test('Ask AI has highest priority (0.95) on feed', () {
      final snapshot = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'v123',
        creatorId: 'c1',
      );
      final actions = engine.evaluate(snapshot);
      expect(actions.first.priority, equals(0.95));
      expect(actions.first.type, equals('ai_video_companion'));
    });

    test('shop action included only when hasCommerceTags is true', () {
      final withTags = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'v1',
        hasCommerceTags: true,
      );
      final withoutTags = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'v1',
        hasCommerceTags: false,
      );
      expect(
        engine.evaluate(withTags).any((a) => a.type == 'commerce'),
        isTrue,
      );
      expect(
        engine.evaluate(withoutTags).any((a) => a.type == 'commerce'),
        isFalse,
      );
    });

    test('coupon action included only when hasActiveCoupon is true', () {
      final snap = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'v1',
        hasActiveCoupon: true,
      );
      expect(engine.evaluate(snap).any((a) => a.type == 'coupon'), isTrue);
    });

    test('poll action included only when hasPoll is true', () {
      final snap = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'v1',
        hasPoll: true,
      );
      expect(engine.evaluate(snap).any((a) => a.type == 'poll'), isTrue);
    });

    test('live action included only when isLiveAvailable is true', () {
      final snap = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'v1',
        creatorId: 'c1',
        isLiveAvailable: true,
      );
      expect(engine.evaluate(snap).any((a) => a.type == 'live'), isTrue);
    });

    test('chat action included only when canMessageCreator is true', () {
      final snap = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'v1',
        creatorId: 'c1',
        canMessageCreator: true,
      );
      expect(engine.evaluate(snap).any((a) => a.type == 'chat'), isTrue);
    });

    test('Ads Arena action always present', () {
      final snap = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'v1',
      );
      expect(
        engine.evaluate(snap).any((a) => a.type == 'rewarded_ads'),
        isTrue,
      );
    });

    test('results capped at 5 actions', () {
      final snap = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'v1',
        creatorId: 'c1',
        hasCommerceTags: true,
        hasActiveCoupon: true,
        hasPoll: true,
        isLiveAvailable: true,
        canMessageCreator: true,
      );
      expect(engine.evaluate(snap).length, lessThanOrEqualTo(5));
    });

    test('actions are sorted by priority descending', () {
      final snap = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'v1',
        creatorId: 'c1',
        hasCommerceTags: true,
        hasActiveCoupon: true,
      );
      final actions = engine.evaluate(snap);
      for (int i = 0; i < actions.length - 1; i++) {
        expect(actions[i].priority, greaterThanOrEqualTo(actions[i + 1].priority));
      }
    });

    test('action ids encode videoId and creatorId', () {
      final snap = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'feed',
        videoId: 'vid42',
        creatorId: 'creator99',
        canMessageCreator: true,
      );
      final actions = engine.evaluate(snap);
      expect(actions.any((a) => a.id.contains('vid42')), isTrue);
      expect(actions.any((a) => a.id.contains('creator99')), isTrue);
    });

    test('ContextActionModel holds all required fields', () {
      const action = ContextActionModel(
        id: 'test_id',
        title: 'Test',
        subtitle: 'Sub',
        type: 'test_type',
        route: '/test',
        priority: 0.9,
        arguments: {'key': 'value'},
      );
      expect(action.id, equals('test_id'));
      expect(action.priority, equals(0.9));
      expect(action.arguments['key'], equals('value'));
    });

    test('no actions on non-feed screen without videoId', () {
      final snap = ContextSnapshotModel(
        userId: 'u1',
        currentScreen: 'profile',
      );
      // Only Ads Arena should appear (not AI, not commerce, etc.)
      final actions = engine.evaluate(snap);
      expect(actions.any((a) => a.type == 'ai_video_companion'), isFalse);
      expect(actions.any((a) => a.type == 'rewarded_ads'), isTrue);
    });
  });
}
