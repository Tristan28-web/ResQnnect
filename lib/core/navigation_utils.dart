import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';

class AppNavigation {
  /// Safely navigates back:
  /// 1. If an [onBack] callback is provided (e.g. embedded inside Dashboard tab), invokes it.
  /// 2. If the Navigator can pop (route was pushed), pops back to caller.
  /// 3. Otherwise (root route or edge case), resets safely to DashboardScreen so screen NEVER turns black.
  static void popOrHome(BuildContext context, {VoidCallback? onBack}) {
    if (onBack != null) {
      onBack();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }
}
