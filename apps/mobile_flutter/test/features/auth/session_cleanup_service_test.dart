import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/auth/session_cleanup_service.dart';

class _FakeStore implements SessionScopedState {
  _FakeStore({this.shouldFail = false});

  final bool shouldFail;
  bool cleared = false;

  @override
  Future<void> clearSession() async {
    if (shouldFail) throw StateError('boom');
    cleared = true;
  }
}

void main() {
  group('YohPalSessionCleanupService', () {
    test('clears every store when all succeed', () async {
      final storeA = _FakeStore();
      final storeB = _FakeStore();
      final service = YohPalSessionCleanupService(stores: [storeA, storeB]);

      await service.clearAll();

      expect(storeA.cleared, isTrue);
      expect(storeB.cleared, isTrue);
    });

    test('still clears the remaining stores when one fails, then throws',
        () async {
      final failing = _FakeStore(shouldFail: true);
      final healthy = _FakeStore();
      final service = YohPalSessionCleanupService(stores: [failing, healthy]);

      await expectLater(service.clearAll(), throwsStateError);

      // The failure of one store must not stop the others from clearing —
      // this is what lets AuthController.logout() treat cleanup as
      // best-effort without silently skipping healthy stores.
      expect(healthy.cleared, isTrue);
    });
  });
}
