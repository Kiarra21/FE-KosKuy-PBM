import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../routes/slide_page_route.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/management_widgets.dart';
import 'owner_bottom_nav.dart';
import 'owner_facility_screen.dart';
import 'owner_room_branch_screen.dart';
import 'owner_user_screen.dart';

class OwnerManagementScreen extends StatelessWidget {
  const OwnerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 22),
                  children: [
                    const Text(
                      'Manajemen Owner',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ManagementActionCard(
                      label: 'Master Fasilitas',
                      icon: Icons.chair_alt_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          SlidePageRoute(child: const OwnerFacilityScreen()),
                        );
                      },
                    ),
                    ManagementActionCard(
                      label: 'Manajemen Kamar',
                      icon: Icons.bed_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          SlidePageRoute(child: const OwnerRoomBranchScreen()),
                        );
                      },
                    ),
                    ManagementActionCard(
                      label: 'Manajemen User',
                      icon: Icons.manage_accounts_rounded,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).push(SlidePageRoute(child: const OwnerUserScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const OwnerBottomNav(selectedIndex: 2),
      ),
    );
  }
}
