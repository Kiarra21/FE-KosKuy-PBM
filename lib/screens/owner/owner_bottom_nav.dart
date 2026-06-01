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
          icon: Icons.home_rounded,
          onTap: selectedIndex == 0
              ? () {}
              : () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const OwnerDashboardScreen()),
                  );
                },
        ),
        ManagementNavItem(
          icon: Icons.grid_view_rounded,
          onTap: selectedIndex == 1
              ? () {}
              : () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const OwnerBranchScreen()),
                  );
                },
        ),
        ManagementNavItem(
          icon: Icons.article_rounded,
          onTap: selectedIndex == 2
              ? () {}
              : () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const OwnerManagementScreen()),
                  );
                },
        ),
        ManagementNavItem(
          icon: Icons.mail_rounded,
          onTap: selectedIndex == 3
              ? () {}
              : () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const OwnerCustomerScreen()),
                  );
                },
        ),
        ManagementNavItem(
          icon: Icons.person_rounded,
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
