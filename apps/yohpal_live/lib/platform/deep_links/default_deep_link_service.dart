import 'yohpal_deep_link_service.dart';

class DefaultDeepLinkService implements YohPalDeepLinkService {
  @override
  YohPalDeepLink? parse(String uri) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null || parsed.scheme != 'yohpal') return null;
    final segments = parsed.pathSegments;
    if (segments.isEmpty) {
      return YohPalDeepLink(
        module: parsed.host,
        entity: '',
        id: '',
      );
    }
    return YohPalDeepLink(
      module: parsed.host,
      entity: segments.length > 0 ? segments[0] : '',
      id: segments.length > 1 ? segments[1] : '',
    );
  }
  @override
  String build({
    required String module,
    required String entity,
    required String id,
  }) {
    return 'yohpal://$module/$entity/$id';
  }
}
