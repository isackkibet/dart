import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class YohPalNativeVideoView extends StatelessWidget {
  const YohPalNativeVideoView({super.key});

  @override
  Widget build(BuildContext context) {
    const viewType = 'yohpal.video/view';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const AndroidView(viewType: viewType);
    }
    return const UiKitView(viewType: viewType);
  }
}
