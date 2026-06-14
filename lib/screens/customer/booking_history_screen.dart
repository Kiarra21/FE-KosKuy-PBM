import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../widgets/app_top_notification.dart';
import '../../models/booking_item.dart';
import '../../providers/booking_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/history_widgets.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/review_widgets.dart';
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
          actionLabel: item.isCompleted && item.hasReview
              ? 'Lihat Review'
              : item.isCompleted && !item.hasReview
              ? 'Review'
              : item.isUnpaid
              ? 'Bayar Sekarang'
              : '',
          onAction: () {
            if (item.isUnpaid) {
              Navigator.of(
                context,
              ).push(SlidePageRoute(child: PaymentScreen(booking: item)));
            } else if (item.isCompleted && !item.hasReview) {
              _showReviewDialog(context, item);
            } else if (item.isCompleted && item.hasReview) {
              _showReviewDetail(context, item);
            }
          },
          onDetail: () {
            Navigator.of(context).push(
              SlidePageRoute(
                child: BookingDetailScreen(
                  booking: item,
                  statusColor: statusColor,
                ),
              ),
            );
          },
          cancelled: item.isCancelled,
        );
      }).toList(),
    );
  }

  void _showReviewDialog(BuildContext context, BookingItem item) {
    int rating = 0;
    final commentController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(builderContext).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Beri Ulasan',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.kosName,
                    style: TextStyle(
                      color: AppColors.navy.withValues(alpha: .6),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StarRatingSelector(
                    rating: rating,
                    onChanged: (value) {
                      setSheetState(() => rating = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar (opsional)',
                      hintStyle: TextStyle(
                        color: AppColors.navy.withValues(alpha: .35),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: AppColors.navy.withValues(alpha: .05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: rating == 0 || submitting
                          ? null
                          : () async {
                              setSheetState(() => submitting = true);
                              final provider = context.read<BookingProvider>();
                              final success = await provider.submitReview(
                                bookingId: item.id,
                                rating: rating,
                                comment: commentController.text.trim().isEmpty
                                    ? null
                                    : commentController.text.trim(),
                              );
                              if (!builderContext.mounted) return;
                              Navigator.of(builderContext).pop();
                              if (success) {
                                showAppTopNotification(
                                  context,
                                  message: 'Ulasan berhasil dikirim!',
                                  type: AppNotificationType.success,
                                );
                              } else {
                                showAppTopNotification(
                                  context,
                                  message: provider.errorMessage ??
                                      'Gagal mengirim ulasan.',
                                  type: AppNotificationType.error,
                                );
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.navy,
                              ),
                            )
                          : const Text(
                              'Kirim Ulasan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReviewDetail(BuildContext context, BookingItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ulasan Kamu',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.kosName,
                style: TextStyle(
                  color: AppColors.navy.withValues(alpha: .6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              StarRatingDisplay(rating: item.reviewRating.toDouble(), size: 28),
              const SizedBox(height: 6),
              Text(
                '${item.reviewRating}/5',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (item.reviewComment.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.reviewComment,
                    style: TextStyle(
                      color: AppColors.navy.withValues(alpha: .8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (item.reviewCreatedAt.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Dikirim pada ${item.reviewCreatedAt}',
                  style: TextStyle(
                    color: AppColors.navy.withValues(alpha: .4),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
