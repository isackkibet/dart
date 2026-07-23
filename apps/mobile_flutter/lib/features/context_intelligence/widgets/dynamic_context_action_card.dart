import 'package:flutter/material.dart';
import '../models/context_action_model.dart';

class DynamicContextActionCard extends StatelessWidget {
  final ContextActionModel action;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const DynamicContextActionCard({
    super.key,
    required this.action,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xEE101020),
      child: ListTile(
        leading: const Icon(Icons.auto_awesome, color: Color(0xFF8E7CFF)),
        title: Text(action.title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(action.subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: onDismiss,
        ),
        onTap: onTap,
      ),
    );
  }
}
