import 'package:flutter/material.dart';
import 'contextual_pip_action.dart';

class ContextualFloatingDock extends StatelessWidget {
  final List<ContextualPipAction> actions;
  final void Function(ContextualPipAction action) onAction;
  const ContextualFloatingDock({
    super.key,
    required this.actions,
    required this.onAction,
  });
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: actions.take(4).map((action) {
        return ActionChip(
          label: Text(action.label),
          avatar: const Icon(Icons.bolt, size: 16),
          onPressed: () => onAction(action),
        );
      }).toList(),
    );
  }
}
