import 'package:flutter/material.dart';

class CreatorProfileGesture extends StatelessWidget {
  const CreatorProfileGesture({
    required this.child,
    required this.onOpenCreator,
    super.key,
  });

  final Widget child;
  final VoidCallback onOpenCreator;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: _handleDragEnd,
      child: child,
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    final v = details.velocity.pixelsPerSecond;
    if (v.dx.abs() <= v.dy.abs()) return;
    if (v.dx > 500) onOpenCreator();
  }
}
