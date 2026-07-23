// URI scheme: yohpal://<module>/<entity>/<id>
// Examples:
//   yohpal://live/creator/123
//   yohpal://jobs/job/987
//   yohpal://hustle/provider/22
//   yohpal://market/product/44
//   yohpal://wallet
//   yohpal://ycios/project/55
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
