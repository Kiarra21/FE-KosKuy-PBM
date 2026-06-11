import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/kos_item.dart';
import '../../providers/customer_room_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/filter_sheet.dart';
import '../../widgets/home_widgets.dart';
import 'booking_history_screen.dart';
import 'detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _filterOpen = false;
  String? _selectedType;
  String? _selectedArea;

  List<KosItem> _filteredItems(List<KosItem> items) {
    return items.where((item) {
      final matchType = _selectedType == null || item.type == _selectedType;
      final matchArea = _selectedArea == null || item.areaName == _selectedArea;
      return matchType && matchArea;
    }).toList();
  }

  bool get _hasFilter => _selectedType != null || _selectedArea != null;

  String get _filterLabel {
    return [
      if (_selectedType != null) _selectedType,
      if (_selectedArea != null) _selectedArea,
    ].join(', ');
  }

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    await context.read<CustomerRoomProvider>().fetchRoomTypes(isActive: true);
  }

  void _openDetail(KosItem item) {
    Navigator.of(context).push(SlidePageRoute(child: DetailScreen(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<CustomerRoomProvider>();
    final filteredItems = _filteredItems(roomProvider.items);
    final loading = roomProvider.loading;
    final errorMessage = roomProvider.errorMessage;
    return AppFrame(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.white,
            body: SafeArea(
              child: Column(
                children: [
                  const HomeHeader(),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.gold,
                      onRefresh: _fetchRooms,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Rekomendasi Kos di Jember',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: loading
                                      ? null
                                      : () =>
                                            setState(() => _filterOpen = true),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.tune_rounded,
                                          color: AppColors.gold,
                                          size: 21,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'Filter',
                                          style: TextStyle(
                                            color: AppColors.gold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: _hasFilter
                                ? Padding(
                                    key: ValueKey(_filterLabel),
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Menampilkan data dengan filter : $_filterLabel',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.navy,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedType = null;
                                              _selectedArea = null;
                                            });
                                          },
                                          child: const Text(
                                            'Hapus Filter',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(height: 0),
                          ),
                          const SizedBox(height: 8),
                          if (loading)
                            const HomeLoadingState()
                          else if (errorMessage != null)
                            HomeErrorState(
                              message: errorMessage,
                              onRetry: _fetchRooms,
                            )
                          else if (filteredItems.isEmpty)
                            const EmptyFilterState()
                          else
                            for (
                              var index = 0;
                              index < filteredItems.length;
                              index++
                            )
                              TweenAnimationBuilder<double>(
                                key: ValueKey(
                                  '${filteredItems[index].id}-${filteredItems[index].name}-$_filterLabel',
                                ),
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(
                                  milliseconds: 500 + (index * 120),
                                ),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 22 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: KosCard(
                                  item: filteredItems[index],
                                  onDetailTap: () =>
                                      _openDetail(filteredItems[index]),
                                  onOrderTap: () =>
                                      _openDetail(filteredItems[index]),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E2E2),
                border: Border.all(color: const Color(0xFF9A9A9A), width: 1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  BottomNavIcon(
                    icon: Icons.home_rounded,
                    selected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  BottomNavIcon(
                    icon: Icons.receipt_long_rounded,
                    selected: _selectedIndex == 1,
                    onTap: () {
                      setState(() => _selectedIndex = 1);
                      Navigator.of(context).pushReplacement(
                        SlidePageRoute(child: const BookingHistoryScreen()),
                      );
                    },
                  ),
                  BottomNavIcon(
                    icon: Icons.account_circle_rounded,
                    selected: _selectedIndex == 2,
                    onTap: () {
                      setState(() => _selectedIndex = 2);
                      Navigator.of(context).pushReplacement(
                        SlidePageRoute(child: const ProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          IgnorePointer(
            ignoring: !_filterOpen,
            child: AnimatedOpacity(
              opacity: _filterOpen ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: GestureDetector(
                onTap: () => setState(() => _filterOpen = false),
                child: Container(color: Colors.black.withValues(alpha: .52)),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _filterOpen ? 0 : -360,
            child: FilterSheet(
              initialType: _selectedType,
              initialArea: _selectedArea,
              onApply: (type, area) {
                setState(() {
                  _selectedType = type;
                  _selectedArea = area;
                  _filterOpen = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
