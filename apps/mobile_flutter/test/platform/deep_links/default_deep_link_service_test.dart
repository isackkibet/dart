import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/platform/deep_links/default_deep_link_service.dart';

void main() {
  late DefaultDeepLinkService service;

  setUp(() => service = DefaultDeepLinkService());

  group('parse', () {
    test('parses a full deep link', () {
      final link = service.parse('yohpal://live/creator/123');
      expect(link?.module, 'live');
      expect(link?.entity, 'creator');
      expect(link?.id, '123');
    });

    test('parses a wallet link with no entity or id', () {
      final link = service.parse('yohpal://wallet');
      expect(link?.module, 'wallet');
      expect(link?.entity, '');
      expect(link?.id, '');
    });

    test('parses jobs deep link', () {
      final link = service.parse('yohpal://jobs/job/987');
      expect(link?.module, 'jobs');
      expect(link?.entity, 'job');
      expect(link?.id, '987');
    });

    test('returns null for non-yohpal scheme', () {
      expect(service.parse('https://yohpal.com/live'), isNull);
    });

    test('returns null for invalid URI', () {
      expect(service.parse('not a uri :::'), isNull);
    });
  });

  group('build', () {
    test('builds a full deep link', () {
      final uri = service.build(module: 'wallet', entity: 'transaction', id: 'abc');
      expect(uri, 'yohpal://wallet/transaction/abc');
    });

    test('builds a market product link', () {
      final uri = service.build(module: 'market', entity: 'product', id: '44');
      expect(uri, 'yohpal://market/product/44');
    });

    test('build then parse is symmetric', () {
      final uri = service.build(module: 'hustle', entity: 'provider', id: '22');
      final link = service.parse(uri);
      expect(link?.module, 'hustle');
      expect(link?.entity, 'provider');
      expect(link?.id, '22');
    });
  });
}
