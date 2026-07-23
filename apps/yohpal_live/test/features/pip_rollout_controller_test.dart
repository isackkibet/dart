import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live/features/pip/pip_rollout_controller.dart';

void main() {
  test('allow-listed user is enabled', () {
    final controller = PipRolloutController(
      enabled: true,
      rolloutPercentage: 0,
      allowListedUsers: {'user1'},
    );
    expect(controller.isEnabledFor('user1'), true);
    expect(controller.isEnabledFor('user2'), false);
  });
}
