import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live/features/pip/contextual/contextual_pip_resolver.dart';

void main() {
  test('resolves contextual actions for live video', () {
    final resolver = ContextualPipResolver();
    final actions = resolver.resolve(
      videoId: 'vid1',
      creatorId: 'creator1',
      live: true,
    );
    expect(actions.length, greaterThan(3));
    expect(actions.any((a) => a.label == 'Like'), true);
    expect(actions.any((a) => a.label == 'Gift'), true);
  });
}
