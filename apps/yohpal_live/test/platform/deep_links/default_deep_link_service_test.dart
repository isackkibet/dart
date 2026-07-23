import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live/platform/deep_links/default_deep_link_service.dart';

void main() {
  test('parses YohPal deep link', () {
    final service = DefaultDeepLinkService();
    final link = service.parse('yohpal://live/creator/123');
    expect(link?.module, 'live');
    expect(link?.entity, 'creator');
    expect(link?.id, '123');
  });
  test('builds YohPal deep link', () {
    final service = DefaultDeepLinkService();
    final uri = service.build(
      module: 'wallet',
      entity: 'transaction',
      id: 'abc',
    );
    expect(uri, 'yohpal://wallet/transaction/abc');
  });
}
