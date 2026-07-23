import 'package:flutter/material.dart';
import '../../core/auth/yohpal_auth_scope.dart';
import '../../core/auth/yohpal_user_role.dart';
import '../widgets/yohpal_error_view.dart';
import '../widgets/yohpal_loading.dart';

class YohPalAuthGuard extends StatelessWidget {
  const YohPalAuthGuard({
    super.key,
    required this.child,
    this.requiredRole,
    this.fallback,
  });

  final Widget child;
  final YohPalUserRole? requiredRole;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final auth = YohPalAuthScope.of(context);
    if (auth.isLoading) {
      return const YohPalLoading(message: 'Checking session...');
    }
    final user = auth.user;
    if (user == null) {
      return fallback ??
          const YohPalErrorView(
            message: 'You need to login to access this page.',
          );
    }
    if (requiredRole != null && user.role != requiredRole && !user.isAdmin) {
      return const YohPalErrorView(
        message: 'You do not have permission to access this page.',
      );
    }
    return child;
  }
}
