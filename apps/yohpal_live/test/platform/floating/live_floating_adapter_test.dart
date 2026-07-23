import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live/platform/floating/adapters/live_floating_adapter.dart';
import 'package:yohpal_live/platform/floating/context/floating_context.dart';

void main() {
  test('live adapter resolves actions', () async {
    final adapter = LiveFloatingAdapter();
    final actions = await adapter.resolveActions(
      const FloatingContext(
        module: 'live',
        entityId: 'vid1',
        title: 'Test',
        isLive: true,
        payload: {'creatorId': 'creator1'},
      ),
    );
    expect(actions.length, greaterThan(2));
    expect(actions.any((a) => a.label == 'Like'), true);
  });
}
