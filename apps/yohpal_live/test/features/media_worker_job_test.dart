import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live/features/media_pipeline/jobs/media_worker_job.dart';
void main() {
  test('MediaWorkerJob serializes correctly', () {
    final job = MediaWorkerJob(
      id: 'job1',
      sessionId: 'session1',
      creatorId: 'creator1',
      jobType: 'clip',
      status: 'queued',
      inputUrl: 'https://example.com/input.mp4',
      createdAt: DateTime.parse('2026-07-06T10:00:00Z'),
    );
    final map = job.toMap();
    expect(map['sessionId'], 'session1');
    expect(map['creatorId'], 'creator1');
    expect(map['jobType'], 'clip');
    expect(map['status'], 'queued');
  });
}
