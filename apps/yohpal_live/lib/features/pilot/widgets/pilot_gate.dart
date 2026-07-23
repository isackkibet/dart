import 'package:flutter/material.dart';
import '../../../core/config/pilot_flags.dart';

class PilotGate extends StatelessWidget {
  final Widget child;
  const PilotGate({
    super.key,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    if (!PilotFlags.multistreamPilot) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Multistreaming is not yet available.",
          ),
        ),
      );
    }
    return child;
  }
}
