import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/admin_management_item.dart';
import '../../models/auth_session.dart';
import '../../models/branch_item.dart';
import '../../models/managed_room.dart';
import '../../models/occupancy_item.dart';
import '../../providers/branch_provider.dart';
import '../../providers/owner_room_provider.dart';
import '../../services/admin_management_service.dart';
import '../../widgets/admin_branch_badge.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/management_widgets.dart';
import 'admin_bottom_nav.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;
  OccupancyItem? _occupancy;
  List<AdminBookingItem> _bookings = const [];
  List<AdminPaymentItem> _payments = const [];
  List<AdminReviewItem> _reviews = const [];

  int? get _branchId => AuthSessionStore.instance.user?.branchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchDashboard();
    });
  }

  Future<void> _fetchDashboard() async {
    final branchId = _branchId;
    if (branchId == null || branchId <= 0) {
      setState(() {
        _loading = false;
        _error = 'Admin belum terhubung cabang.';
        _occupancy = null;
        _bookings = const [];
        _payments = const [];
        _reviews = const [];
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
      const adminService = AdminManagementService();
      final results = await Future.wait([
        branchProvider.fetchBranch(branchId),
        roomProvider.fetchRoomTypes(branchId),
        adminService.fetchBookings(),
        adminService.fetchPayments(),
        adminService.fetchBranchReviews(branchId),
      ]);
      if (!mounted) return;
      final branch = results[0] as BranchItem;
      final roomTypes = results[1] as List<ManagedRoomType>;
      final bookings = results[2] as List<AdminBookingItem>;
      final payments = results[3] as List<AdminPaymentItem>;
      final reviews = results[4] as List<AdminReviewItem>;
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
        _bookings = bookings;
        _payments = payments;
        _reviews = reviews;
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
              const HomeHeader(showNotification: false),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _fetchDashboard,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
                    children: [
                      const AdminBranchBadge(),
                      const SizedBox(height: 14),
                      const Text(
                        'Statistik Cabang',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StatsSection(
                        loading: _loading,
                        error: _error,
                        bookings: _bookings,
                        payments: _payments,
                      ),
                      const SizedBox(height: 18),
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
                        onRetry: _fetchDashboard,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Ulasan Terbaru',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ReviewSection(
                        loading: _loading,
                        error: _error,
                        reviews: _reviews,
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

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.loading,
    required this.error,
    required this.reviews,
  });

  final bool loading;
  final String? error;
  final List<AdminReviewItem> reviews;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (error != null) {
      return Container(
        height: 86,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Ulasan belum bisa dimuat.',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900),
        ),
      );
    }
    final visibleReviews = reviews.where((item) => item.isVisible).toList()
      ..sort((a, b) {
        final first = a.createdDate;
        final second = b.createdDate;
        if (first == null && second == null) return b.id.compareTo(a.id);
        if (first == null) return 1;
        if (second == null) return -1;
        return second.compareTo(first);
      });
    if (visibleReviews.isEmpty) {
      return Container(
        height: 86,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Belum ada ulasan untuk cabang ini.',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900),
        ),
      );
    }
    final totalReviews = visibleReviews.length;
    final averageRating =
        visibleReviews.fold<int>(0, (total, item) => total + item.rating) /
        totalReviews;
    final ratingCounts = {
      for (var rating = 5; rating >= 1; rating--)
        rating: visibleReviews.where((item) => item.rating == rating).length,
    };
    final previewReviews = visibleReviews.take(2).toList();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 82,
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _StarRow(rating: averageRating, size: 14),
                      const SizedBox(height: 6),
                      Text(
                        '$totalReviews ulasan',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: .76),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: ratingCounts.entries
                        .map(
                          (entry) => _RatingBar(
                            rating: entry.key,
                            count: entry.value,
                            total: totalReviews,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.white.withValues(alpha: .12), height: 1),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Komentar Terbaru',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .78),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...previewReviews.map((item) => _ReviewCard(item: item)),
            if (visibleReviews.length > previewReviews.length) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _showAllReviews(context, visibleReviews),
                  child: const Text(
                    'Lihat Semua Review',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAllReviews(BuildContext context, List<AdminReviewItem> reviews) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
          decoration: const BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Semua Review',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: reviews
                        .map((item) => _ReviewCard(item: item))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item});

  final AdminReviewItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Row(
                children: [
                  if (item.createdAt != '-')
                    Text(
                      item.createdAt,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: .68),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          _StarRow(rating: item.rating.toDouble(), size: 14),
          if (item.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.comment,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.rating,
    required this.count,
    required this.total,
  });

  final int rating;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Row(
              children: [
                Text(
                  '$rating',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 11),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: AppColors.white.withValues(alpha: .15),
                color: AppColors.gold,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: .78),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, required this.size});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final icon = rating >= starValue
            ? Icons.star_rounded
            : rating > index
            ? Icons.star_half_rounded
            : Icons.star_border_rounded;
        return Icon(icon, color: AppColors.gold, size: size);
      }),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.loading,
    required this.error,
    required this.bookings,
    required this.payments,
  });

  final bool loading;
  final String? error;
  final List<AdminBookingItem> bookings;
  final List<AdminPaymentItem> payments;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _StatsGrid(
        items: [
          _StatItem('Booking', '...', Icons.assignment_rounded),
          _StatItem('Pembayaran Valid', '...', Icons.verified_rounded),
          _StatItem('Menunggu Bayar', '...', Icons.hourglass_top_rounded),
          _StatItem('Pemasukan Bulan Ini', '...', Icons.savings_rounded),
        ],
      );
    }
    if (error != null) {
      return const _StatsGrid(
        items: [
          _StatItem('Booking', '-', Icons.assignment_rounded),
          _StatItem('Pembayaran Valid', '-', Icons.verified_rounded),
          _StatItem('Menunggu Bayar', '-', Icons.hourglass_top_rounded),
          _StatItem('Pemasukan Bulan Ini', '-', Icons.savings_rounded),
        ],
      );
    }
    final paidPayments = payments
        .where((item) => item.status == AdminPaymentStatus.paid)
        .toList();
    final waitingPayments = payments
        .where(
          (item) =>
              !item.hasPaymentRecord ||
              item.status == AdminPaymentStatus.pending,
        )
        .length;
    final now = DateTime.now();
    final monthlyIncome = paidPayments
        .where((item) {
          final date = item.createdDate;
          return date != null &&
              date.month == now.month &&
              date.year == now.year;
        })
        .fold<double>(0, (total, item) => total + item.amountRaw);
    return _StatsGrid(
      items: [
        _StatItem('Booking', '${bookings.length}', Icons.assignment_rounded),
        _StatItem(
          'Pembayaran Valid',
          '${paidPayments.length}',
          Icons.verified_rounded,
        ),
        _StatItem(
          'Menunggu Bayar',
          '$waitingPayments',
          Icons.hourglass_top_rounded,
        ),
        _StatItem(
          'Pemasukan Bulan Ini',
          _rupiah(monthlyIncome),
          Icons.savings_rounded,
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
        ),
        itemBuilder: (context, index) => _StatCard(item: items[index]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: .45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: AppColors.gold, size: 19),
          const Spacer(),
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.value,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

String _rupiah(double value) {
  final number = value.round();
  final text = number.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    final remaining = text.length - index;
    buffer.write(text[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return 'Rp$buffer';
}
