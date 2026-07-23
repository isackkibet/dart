class YohPalDeepLink {
  final String module;
  final String entity;
  final String id;
  const YohPalDeepLink({
    required this.module,
    required this.entity,
    required this.id,
  });
}

abstract class YohPalDeepLinkService {
  YohPalDeepLink? parse(String uri);
  String build({
    required String module,
    required String entity,
    required String id,
  });
}
