import 'package:flutter/widgets.dart';

class YohPalLiveFeatureGuard {
  final bool releaseAllowed;
  final bool userEligible;
  final bool killSwitchEnabled;

  const YohPalLiveFeatureGuard({
    required this.releaseAllowed,
    required this.userEligible,
    required this.killSwitchEnabled,
  });

  bool get canShowYohPalLive {
    return releaseAllowed && userEligible && !killSwitchEnabled;
  }

  static const YohPalLiveFeatureGuard blocked = YohPalLiveFeatureGuard(
    releaseAllowed: false,
    userEligible: false,
    killSwitchEnabled: false,
  );
}

Widget buildYohPalLiveEntry(YohPalLiveFeatureGuard guard, Widget livePage) {
  if (!guard.canShowYohPalLive) {
    return const SizedBox.shrink();
  }
  return livePage;
}
