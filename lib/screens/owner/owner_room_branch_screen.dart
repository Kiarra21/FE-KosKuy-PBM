import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/branch_item.dart';
import '../../providers/branch_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'owner_bottom_nav.dart';
import 'owner_room_screen.dart';

class OwnerRoomBranchScreen extends StatefulWidget {
  const OwnerRoomBranchScreen({super.key});

  @override
  State<OwnerRoomBranchScreen> createState() => _OwnerRoomBranchScreenState();
}

class _OwnerRoomBranchScreenState extends State<OwnerRoomBranchScreen> {
  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    await context.read<BranchProvider>().fetchBranches();
  }

  Future<void> _openRooms(BranchItem item) async {
    await Navigator.of(
      context,
    ).push(SlidePageRoute(child: OwnerRoomScreen(branch: item)));
    _fetch();
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
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Manajemen Kamar',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _content()),
            ],
          ),
        ),
        bottomNavigationBar: const OwnerBottomNav(selectedIndex: 2),
      ),
    );
  }

  Widget _content() {
    final branchProvider = context.watch<BranchProvider>();
    final items = branchProvider.branches;
    if (branchProvider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (branchProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                branchProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.navy),
              ),
              const SizedBox(height: 10),
              FilledButton(onPressed: _fetch, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _fetch,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: Text(
                  'Belum ada cabang.',
                  style: TextStyle(color: AppColors.navy),
                ),
              ),
            )
          else
            for (final item in items)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.apartment_rounded,
                    color: AppColors.gold,
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    item.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.navy,
                  ),
                  onTap: () => _openRooms(item),
                ),
              ),
        ],
      ),
    );
  }
}
