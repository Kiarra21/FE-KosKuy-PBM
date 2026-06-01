import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/occupancy_item.dart';
import '../../providers/branch_provider.dart';
import '../../providers/owner_room_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/management_widgets.dart';
import 'owner_bottom_nav.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<OccupancyItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final branchProvider = context.read<BranchProvider>();
      final roomProvider = context.read<OwnerRoomProvider>();
      await branchProvider.fetchBranches();
      if (branchProvider.errorMessage != null) {
        throw AuthException(branchProvider.errorMessage!);
      }
      final branches = branchProvider.branches;
      final items = <OccupancyItem>[];
      for (final branch in branches) {
        final roomTypes = await roomProvider.fetchRoomTypes(branch.id);
        items.add(
          OccupancyItem(
            name: branch.name,
            type: branch.isActive ? 'Aktif' : 'Nonaktif',
            typeColor: branch.isActive ? Colors.green : Colors.red,
            rooms: roomTypes
                .map(
                  (roomType) => RoomOccupancy(
                    name: roomType.name,
                    total: roomType.roomsCount,
                    filled: roomType.filledRoomsCount,
                  ),
                )
                .toList(),
          ),
        );
      }
      if (!mounted) return;
      setState(() => _items = items);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
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
                  onRefresh: _fetch,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
                    children: [
                      const Text(
                        'Okupansi Kos',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const SizedBox(
                          height: 220,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gold,
                            ),
                          ),
                        )
                      else if (_errorMessage != null)
                        SizedBox(
                          height: 220,
                          child: Center(
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      else if (_items.isEmpty)
                        const SizedBox(
                          height: 220,
                          child: Center(
                            child: Text(
                              'Belum ada data cabang.',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      else
                        for (var index = 0; index < _items.length; index++)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(
                              milliseconds: 420 + (index * 100),
                            ),
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
                            child: OccupancyCard(item: _items[index]),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const OwnerBottomNav(selectedIndex: 0),
      ),
    );
  }
}
