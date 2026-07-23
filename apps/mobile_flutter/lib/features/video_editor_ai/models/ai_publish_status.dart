/// Mirrors the `aiPublishStatus` field on a `videos/{id}` document.
///
/// Only `notReady`/`ready` are ever actually written by this app today —
/// there's no AI moderation backend producing an async review outcome, so a
/// `pending`/`rejected` state would never be reachable in practice. Keeping
/// the enum limited to what the data model can actually produce, rather
/// than a review workflow this app doesn't have.
enum AiPublishStatus {
  notReady,
  ready,
}

/// Centralizes the "AI checklist must be complete before publishing" rule
/// that previously lived only as an inline `allDone` bool in
/// ai_editor_screen.dart's widget state — that made the gate reset every
/// time the creator left and returned to the screen. This class is backed
/// by the persisted Firestore status instead (see
/// AiPublishRepository.watchAiPublishStatus), so it survives navigation.
final class PublishEligibility {
  const PublishEligibility({required this.aiPublishStatus});

  final AiPublishStatus aiPublishStatus;

  bool get canPublish => aiPublishStatus == AiPublishStatus.ready;

  String? get blockingReason {
    if (canPublish) return null;
    return 'Complete the AI enhancement checklist before publishing.';
  }
}
