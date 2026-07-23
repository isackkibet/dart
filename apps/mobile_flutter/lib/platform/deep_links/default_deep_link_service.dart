import 'yohpal_deep_link_service.dart';

class DefaultDeepLinkService implements YohPalDeepLinkService {
  @override
  YohPalDeepLink? parse(String uri) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null || parsed.scheme != 'yohpal') return null;
    final segments = parsed.pathSegments;
    return YohPalDeepLink(
      module: parsed.host,
      entity: segments.isNotEmpty ? segments[0] : '',
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
