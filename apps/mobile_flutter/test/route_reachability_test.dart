import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/app/router.dart';

void main() {
  group('YohPalRouter reachability', () {
    final routes = YohPalRouter.routes;

    test('routes map is non-empty', () {
      expect(routes, isNotEmpty);
    });

    test('every registered route has a non-empty key and non-null builder', () {
      for (final entry in routes.entries) {
        expect(
          entry.key,
          isNotEmpty,
          reason: 'route key must be a non-empty string',
        );
        expect(
          entry.value,
          isNotNull,
          reason: 'builder for "${entry.key}" must be non-null',
        );
      }
    });

    test('dead route /creator-analytics is not registered (regression guard)', () {
      expect(
        routes.containsKey('/creator-analytics'),
        isFalse,
        reason:
            '/creator-analytics was never registered; use /creator-profile/analytics',
      );
      expect(
        routes.containsKey('/creator-profile/analytics'),
        isTrue,
        reason: '/creator-profile/analytics must be reachable',
      );
    });

    test('all route keys start with /', () {
      for (final key in routes.keys) {
        expect(
          key.startsWith('/'),
          isTrue,
          reason: 'route "$key" must start with /',
        );
      }
    });
  });
}
