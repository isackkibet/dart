import 'package:url_launcher/url_launcher.dart';
import 'contextual_pip_action.dart';

class ContextualPipRouter {
  Future<void> open(ContextualPipAction action) async {
    final uri = Uri.parse(action.deepLink);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Unable to open ${action.deepLink}');
    }
  }
}
