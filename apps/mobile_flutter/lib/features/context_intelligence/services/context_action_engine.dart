import 'package:flutter/material.dart';
import '../models/context_action_model.dart';

class ContextActionEngine {
  Future<void> execute(
    BuildContext context,
    ContextActionModel action,
  ) async {
    Navigator.pushNamed(context, action.route, arguments: action.arguments);
  }

  Future<void> executeWithNavigator(
    NavigatorState navigator,
    ContextActionModel action,
  ) async {
    navigator.pushNamed(action.route, arguments: action.arguments);
  }
}
