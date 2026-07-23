import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/video_editor_ai/models/ai_publish_status.dart';

void main() {
  group('PublishEligibility', () {
    test('cannot publish when status is notReady', () {
      const eligibility = PublishEligibility(
        aiPublishStatus: AiPublishStatus.notReady,
      );
      expect(eligibility.canPublish, isFalse);
      expect(eligibility.blockingReason, isNotNull);
    });

    test('can publish once status is ready', () {
      const eligibility = PublishEligibility(
        aiPublishStatus: AiPublishStatus.ready,
      );
      expect(eligibility.canPublish, isTrue);
      expect(eligibility.blockingReason, isNull);
    });
  });
}
