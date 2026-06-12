import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/auth_session.dart';
import '../../models/branch_item.dart';
import '../../models/managed_room.dart';
import '../../models/occupancy_item.dart';
import '../../providers/branch_provider.dart';
import '../../providers/owner_room_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../widgets/admin_branch_badge.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/management_widgets.dart';
import 'admin_booking_screen.dart';
import 'admin_bottom_nav.dart';
import 'admin_payment_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;
  OccupancyItem? _occupancy;

  int? get _branchId => AuthSessionStore.instance.user?.branchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchOccupancy();
    });
  }

  Future<void> _fetchOccupancy() async {
    final branchId = _branchId;
    if (branchId == null || branchId <= 0) {
      setState(() {
        _loading = false;
        _error = 'Admin belum terhubung cabang.';
        _occupancy = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final branchProvider = context.read<BranchProvider>();
      final roomProvider = context.read<OwnerRoomProvider>();
      final results = await Future.wait([
        branchProvider.fetchBranch(branchId),
        roomProvider.fetchRoomTypes(branchId),
      ]);
      if (!mounted) return;
      final branch = results[0] as BranchItem;
      final roomTypes = results[1] as List<ManagedRoomType>;
      setState(() {
        _occupancy = OccupancyItem(
          name: branch.name,
          type: branch.isActive ? 'Aktif' : 'Non Aktif',
          typeColor: branch.isActive ? Colors.green : Colors.red,
          rooms: roomTypes
              .map(
                (item) => RoomOccupancy(
                  name: item.name,
                  total: item.roomsCount,
                  filled: item.filledRoomsCount < 0 ? 0 : item.filledRoomsCount,
                ),
              )
              .toList(),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                child: RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _fetchOccupancy,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
                    children: [
                      const AdminBranchBadge(),
                      const SizedBox(height: 14),
                      const Text(
                        'Okupansi Kos',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _OccupancySection(
                        loading: _loading,
                        error: _error,
                        item: _occupancy,
                        onRetry: _fetchOccupancy,
                      ),
                      const SizedBox(height: 26),
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
                          label: 'Booking',
                          icon: Icons.verified_user_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              SlidePageRoute(child: const AdminBookingScreen()),
                            );
                          },
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
                          label: 'Pembayaran',
                          icon: Icons.payments_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              SlidePageRoute(child: const AdminPaymentScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
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

class _OccupancySection extends StatelessWidget {
  const _OccupancySection({
    required this.loading,
    required this.error,
    required this.item,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final OccupancyItem? item;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 126,
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    final message = error;
    if (message != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: FilledButton(
                onPressed: onRetry,
                child: const Text('Coba Lagi'),
              ),
            ),
          ],
        ),
      );
    }
    final occupancy = item;
    if (occupancy == null || occupancy.rooms.isEmpty) {
      return Container(
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Belum ada tipe kamar di cabang ini.',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900),
        ),
      );
    }
    return TweenAnimationBuilder<double>(
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
      child: OccupancyCard(item: occupancy),
    );
  }
}
