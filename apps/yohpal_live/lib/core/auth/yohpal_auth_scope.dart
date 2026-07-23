import 'package:flutter/material.dart';
import 'yohpal_auth_controller.dart';

class YohPalAuthScope extends InheritedNotifier<YohPalAuthController> {
  const YohPalAuthScope({
    super.key,
    required YohPalAuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static YohPalAuthController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<YohPalAuthScope>();
    assert(scope != null, 'YohPalAuthScope was not found in context.');
    return scope!.notifier!;
  }

  static YohPalAuthController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<YohPalAuthScope>();
    final scope = element?.widget as YohPalAuthScope?;
    assert(scope != null, 'YohPalAuthScope was not found in context.');
    return scope!.notifier!;
  }
}
