import 'package:flutter/material.dart';
import '../actions/floating_action.dart';

class FloatingActionDock extends StatelessWidget {
  final List<FloatingAction> actions;
  final void Function(FloatingAction action) onAction;
  const FloatingActionDock({
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
          onPressed: () => onAction(action),
        );
      }).toList(),
    );
  }
}
