import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live/features/pilot/models/pilot_user.dart';
import 'package:yohpal_live/core/config/pilot_flags.dart';

void main() {
  group('Pilot Models & Config', () {
    test('PilotUser serializes correctly from map', () {
      final json = {
        'uid': 'user123',
        'email': 'test@example.com',
        'role': 'creator',
      };
      final user = PilotUser.fromMap(json);
      expect(user.uid, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.role, 'creator');
    });

    test('PilotFlags defaults are false', () {
      expect(PilotFlags.multistreamPilot, false);
      expect(PilotFlags.giftsEnabled, false);
      expect(PilotFlags.ffmpegEnabled, false);
    });
  });
}
