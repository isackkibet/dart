import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/context_intelligence_controller.dart';
import 'dynamic_context_action_card.dart';

class ContextActionStrip extends StatelessWidget {
  final String userId;

  const ContextActionStrip({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ContextIntelligenceController>();
    final actions = controller.actions;
    if (actions.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 12,
      right: 72,
      bottom: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: actions.take(2).map((action) {
          return DynamicContextActionCard(
            action: action,
            onTap: () => controller.executeAction(
              context: context,
              userId: userId,
              action: action,
            ),
            onDismiss: () => controller.dismissAction(
              userId: userId,
              action: action,
            ),
          );
        }).toList(),
      ),
    );
  }
}
