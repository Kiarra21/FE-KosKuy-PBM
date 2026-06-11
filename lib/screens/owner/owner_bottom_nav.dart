import 'package:flutter/material.dart';

import '../../routes/slide_page_route.dart';
import '../../widgets/management_widgets.dart';
import 'owner_branch_screen.dart';
import 'owner_customer_screen.dart';
import 'owner_dashboard_screen.dart';
import 'owner_management_screen.dart';
import 'owner_profile_screen.dart';

class OwnerBottomNav extends StatelessWidget {
  const OwnerBottomNav({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return ManagementBottomNav(
      selectedIndex: selectedIndex,
      items: [
        ManagementNavItem(
          icon: Icons.dashboard_rounded,
          onTap: selectedIndex == 0
              ? () {}
              : () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const OwnerDashboardScreen()),
                  );
                },
        ),
        ManagementNavItem(
          icon: Icons.apartment_rounded,
          onTap: selectedIndex == 1
              ? () {}
              : () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const OwnerBranchScreen()),
                  );
                },
        ),
        ManagementNavItem(
          icon: Icons.settings_suggest_rounded,
          onTap: selectedIndex == 2
              ? () {}
              : () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const OwnerManagementScreen()),
                  );
                },
        ),
        ManagementNavItem(
          icon: Icons.groups_rounded,
          onTap: selectedIndex == 3
              ? () {}
              : () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const OwnerCustomerScreen()),
                  );
                },
        ),
        ManagementNavItem(
          icon: Icons.account_circle_rounded,
          onTap: selectedIndex == 4
              ? () {}
              : () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const OwnerProfileScreen()),
                  );
                },
        ),
      ],
    );
  }
}
