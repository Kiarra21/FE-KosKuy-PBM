import 'package:flutter/material.dart';

import '../../routes/slide_page_route.dart';
import '../../widgets/management_widgets.dart';
import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return ManagementBottomNav(
      selectedIndex: selectedIndex,
      items: [
        ManagementNavItem(
          icon: Icons.home_rounded,
          onTap: selectedIndex == 0
              ? () {}
              : () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const AdminDashboardScreen()),
                  );
                },
        ),
        ManagementNavItem(icon: Icons.grid_view_rounded, onTap: () {}),
        ManagementNavItem(
          icon: Icons.person_rounded,
          onTap: selectedIndex == 2
              ? () {}
              : () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const AdminProfileScreen()),
                  );
                },
        ),
      ],
    );
  }
}
