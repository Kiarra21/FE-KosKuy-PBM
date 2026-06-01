import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/branch_item.dart';
import '../../providers/branch_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../widgets/branch_widgets.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'owner_bottom_nav.dart';
import 'owner_branch_detail_screen.dart';
import 'owner_branch_form_screen.dart';
import 'owner_room_screen.dart';

class OwnerBranchScreen extends StatefulWidget {
  const OwnerBranchScreen({super.key});

  @override
  State<OwnerBranchScreen> createState() => _OwnerBranchScreenState();
}

class _OwnerBranchScreenState extends State<OwnerBranchScreen> {
  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    await context.read<BranchProvider>().fetchBranches();
  }

  Future<void> _openDetail(BranchItem item) async {
    await Navigator.of(
      context,
    ).push(SlidePageRoute(child: OwnerBranchDetailScreen(item: item)));
    _fetchBranches();
  }

  Future<void> _openCreateForm() async {
    final created = await Navigator.of(
      context,
    ).push(SlidePageRoute(child: const OwnerBranchFormScreen()));
    if (created == true) _fetchBranches();
  }

  void _openRooms(BranchItem item) {
    Navigator.of(
      context,
    ).push(SlidePageRoute(child: OwnerRoomScreen(branch: item)));
  }

  @override
  Widget build(BuildContext context) {
    final branchProvider = context.watch<BranchProvider>();
    final items = branchProvider.branches;
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
                  onRefresh: _fetchBranches,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Daftar Cabang',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 78,
                            height: 32,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF21CF3A),
                                foregroundColor: AppColors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: branchProvider.loading
                                  ? null
                                  : _openCreateForm,
                              child: const Text(
                                'Tambah',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (branchProvider.loading)
                        const BranchLoadingState()
                      else if (branchProvider.errorMessage != null)
                        BranchErrorState(
                          message: branchProvider.errorMessage!,
                          onRetry: _fetchBranches,
                        )
                      else if (items.isEmpty)
                        const BranchEmptyState(message: 'Belum ada cabang.')
                      else
                        for (var index = 0; index < items.length; index++)
                          TweenAnimationBuilder<double>(
                            key: ValueKey(items[index].id),
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 420 + index * 90),
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
                            child: BranchCard(
                              item: items[index],
                              onRooms: () => _openRooms(items[index]),
                              onDetail: () => _openDetail(items[index]),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const OwnerBottomNav(selectedIndex: 1),
      ),
    );
  }
}
