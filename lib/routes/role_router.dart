import 'package:flutter/widgets.dart';

import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/customer/home_screen.dart';
import '../screens/owner/owner_dashboard_screen.dart';

class RoleRouter {
  static Widget screenFor(String role) {
    final normalizedRole = role.toLowerCase().trim();
    if (normalizedRole == 'admin') return const AdminDashboardScreen();
    if (normalizedRole == 'pemilik_kos' ||
        normalizedRole == 'owner' ||
        normalizedRole == 'pemilik kos') {
      return const OwnerDashboardScreen();
    }
    return const HomeScreen();
  }
}
