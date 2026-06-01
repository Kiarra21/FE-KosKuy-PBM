import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/occupancy_item.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/management_widgets.dart';
import 'admin_bottom_nav.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const OccupancyItem _sampleItem = OccupancyItem(
    name: 'Kos Xavier 1',
    type: 'Putra',
    typeColor: AppColors.blue,
    rooms: [
      RoomOccupancy(name: 'Kamar Mandi Dalam', total: 20, filled: 15),
      RoomOccupancy(name: 'Kamar Mandi Luar', total: 30, filled: 28),
    ],
  );

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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
                  children: [
                    const Text(
                      'Okupansi Kos',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: const OccupancyCard(
                        item: _sampleItem,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 44),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: ManagementActionCard(
                        label: 'Verifikasi',
                        icon: Icons.dashboard_rounded,
                        onTap: () {},
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 620),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: ManagementActionCard(
                        label: 'Validasi Kamar',
                        icon: Icons.dashboard_rounded,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AdminBottomNav(selectedIndex: 0),
      ),
    );
  }
}
