import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/booking_item.dart';
import '../../providers/booking_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/history_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'booking_detail_screen.dart';
import 'home_screen.dart';
import 'payment_screen.dart';
import 'profile_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchBookings();
    });
  }

  Future<void> _fetchBookings() async {
    await context.read<BookingProvider>().fetchBookings();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
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
                  onRefresh: _fetchBookings,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                    children: [
                      HistoryTabBar(
                        selectedIndex: _selectedTab,
                        onChanged: (index) =>
                            setState(() => _selectedTab = index),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _HistoryContent(
                          key: ValueKey(
                            '$_selectedTab-${bookingProvider.loading}',
                          ),
                          selectedTab: _selectedTab,
                          loading: bookingProvider.loading,
                          errorMessage: bookingProvider.errorMessage,
                          items: bookingProvider.items,
                          onRetry: _fetchBookings,
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              BottomNavIcon(
                icon: Icons.home_rounded,
                selected: false,
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushReplacement(SlidePageRoute(child: const HomeScreen()));
                },
              ),
              BottomNavIcon(
                icon: Icons.receipt_long_rounded,
                selected: true,
                onTap: () {},
              ),
              BottomNavIcon(
                icon: Icons.account_circle_rounded,
                selected: false,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    super.key,
    required this.selectedTab,
    required this.loading,
    required this.errorMessage,
    required this.items,
    required this.onRetry,
  });

  final int selectedTab;
  final bool loading;
  final String? errorMessage;
  final List<BookingItem> items;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const HistoryLoadingState();
    final error = errorMessage;
    if (error != null) {
      return HistoryErrorState(message: error, onRetry: onRetry);
    }
    final filteredItems = items.where((item) {
      if (selectedTab == 1) return item.isCompleted;
      if (selectedTab == 2) return item.isCancelled;
      return item.isActive;
    }).toList();
    if (filteredItems.isEmpty) {
      return const HistoryEmptyState(message: 'Belum ada pesanan.');
    }
    return Column(
      children: filteredItems.map((item) {
        final statusColor = item.isCancelled
            ? Colors.red.withValues(alpha: .18)
            : item.isCompleted
            ? Colors.greenAccent
            : item.isWaitingVerification || item.isPaid
            ? const Color(0xFF90CAF9)
            : Colors.yellowAccent;
        return BookingHistoryCard(
          item: item,
          status: item.status,
          statusColor: statusColor,
          actionLabel: item.isCompleted
              ? 'Review'
              : item.isUnpaid
              ? 'Bayar Sekarang'
              : '',
          onAction: () {
            if (item.isUnpaid) {
              Navigator.of(context).push(
                SlidePageRoute(child: PaymentScreen(booking: item)),
              );
            }
          },
          onDetail: () {
            Navigator.of(context).push(
              SlidePageRoute(child: BookingDetailScreen(
                booking: item,
                statusColor: statusColor,
              )),
            );
          },
          cancelled: item.isCancelled,
        );
      }).toList(),
    );
  }
}
