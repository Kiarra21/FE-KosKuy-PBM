import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/admin_management_item.dart';
import '../../models/branch_item.dart';
import '../../models/managed_room.dart';
import '../../models/occupancy_item.dart';
import '../../providers/branch_provider.dart';
import '../../providers/owner_room_provider.dart';
import '../../services/admin_management_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'owner_bottom_nav.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<_OwnerBranchDashboardItem> _branchDashboards = const [];
  List<AdminBookingItem> _bookings = const [];
  List<AdminPaymentItem> _payments = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetch();
    });
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _branchDashboards = const [];
      _bookings = const [];
      _payments = const [];
    });
    try {
      final branchProvider = context.read<BranchProvider>();
      const adminService = AdminManagementService();
      await branchProvider.fetchBranches();
      if (branchProvider.errorMessage != null) {
        throw AuthException(branchProvider.errorMessage!);
      }
      final branches = branchProvider.branches;
      if (!mounted) return;
      setState(() {
        _branchDashboards = branches
            .map((branch) => _OwnerBranchDashboardItem.loading(branch))
            .toList();
        _loading = false;
      });
      _loadSharedData(adminService);
      for (final branch in branches) {
        _loadBranchDashboard(branch, adminService);
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted && _branchDashboards.isEmpty) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadSharedData(AdminManagementService service) async {
    try {
      final results = await Future.wait([
        service.fetchBookings(),
        service.fetchPayments(),
      ]);
      if (!mounted) return;
      setState(() {
        _bookings = results[0] as List<AdminBookingItem>;
        _payments = results[1] as List<AdminPaymentItem>;
      });
      for (final item in _branchDashboards) {
        _applyBranchSharedData(item.branch);
      }
    } catch (_) {}
  }

  Future<void> _loadBranchDashboard(
    BranchItem branch,
    AdminManagementService service,
  ) async {
    try {
      final roomProvider = context.read<OwnerRoomProvider>();
      final results = await Future.wait([
        roomProvider.fetchRoomTypes(branch.id),
        _fetchBranchReviews(service, branch.id),
      ]);
      if (!mounted) return;
      final roomTypes = results[0] as List<ManagedRoomType>;
      final reviews = results[1] as List<AdminReviewItem>;
      final occupancy = OccupancyItem(
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
      );
      setState(() {
        _branchDashboards = _branchDashboards.map((item) {
          if (item.branch.id != branch.id) return item;
          return item.copyWith(
            occupancy: occupancy,
            reviews: reviews,
            loadingDetails: false,
          );
        }).toList();
      });
      _applyBranchSharedData(branch);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _branchDashboards = _branchDashboards.map((item) {
          if (item.branch.id != branch.id) return item;
          return item.copyWith(
            loadingDetails: false,
            errorMessage: 'Data cabang ini belum bisa dimuat.',
          );
        }).toList();
      });
    }
  }

  void _applyBranchSharedData(BranchItem branch) {
    if (!mounted) return;
    setState(() {
      _branchDashboards = _branchDashboards.map((item) {
        if (item.branch.id != branch.id) return item;
        return item.copyWith(
          bookings: _bookings
              .where(
                (booking) => _matchesBranch(
                  booking.branchId,
                  booking.branchName,
                  branch,
                ),
              )
              .toList(),
          payments: _payments
              .where(
                (payment) => _matchesBranch(
                  payment.branchId,
                  payment.branchName,
                  branch,
                ),
              )
              .toList(),
          loadingShared: false,
        );
      }).toList();
    });
  }

  bool _matchesBranch(int branchId, String branchName, BranchItem branch) {
    if (branchId > 0) return branchId == branch.id;
    return branchName.trim().toLowerCase() == branch.name.trim().toLowerCase();
  }

  Future<List<AdminReviewItem>> _fetchBranchReviews(
    AdminManagementService service,
    int branchId,
  ) async {
    try {
      return await service.fetchBranchReviews(branchId);
    } catch (_) {
      return const [];
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
                  onRefresh: _fetch,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
                    children: [
                      const Text(
                        'Dashboard Cabang',
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
                      else if (_branchDashboards.isEmpty)
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
                        for (
                          var index = 0;
                          index < _branchDashboards.length;
                          index++
                        )
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
                            child: _OwnerBranchDashboardCard(
                              item: _branchDashboards[index],
                            ),
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

class _OwnerBranchDashboardItem {
  const _OwnerBranchDashboardItem({
    required this.branch,
    required this.occupancy,
    required this.bookings,
    required this.payments,
    required this.reviews,
    this.loadingDetails,
    this.loadingShared,
    this.errorMessage,
  });

  factory _OwnerBranchDashboardItem.loading(BranchItem branch) {
    return _OwnerBranchDashboardItem(
      branch: branch,
      occupancy: OccupancyItem(
        name: branch.name,
        type: branch.isActive ? 'Aktif' : 'Nonaktif',
        typeColor: branch.isActive ? Colors.green : Colors.red,
        rooms: const [],
      ),
      bookings: const [],
      payments: const [],
      reviews: const [],
      loadingDetails: true,
      loadingShared: true,
    );
  }

  final BranchItem branch;
  final OccupancyItem occupancy;
  final List<AdminBookingItem> bookings;
  final List<AdminPaymentItem> payments;
  final List<AdminReviewItem> reviews;
  final bool? loadingDetails;
  final bool? loadingShared;
  final String? errorMessage;

  bool get isLoadingDetails => loadingDetails == true;
  bool get isLoadingShared => loadingShared == true;

  _OwnerBranchDashboardItem copyWith({
    OccupancyItem? occupancy,
    List<AdminBookingItem>? bookings,
    List<AdminPaymentItem>? payments,
    List<AdminReviewItem>? reviews,
    bool? loadingDetails,
    bool? loadingShared,
    String? errorMessage,
  }) {
    return _OwnerBranchDashboardItem(
      branch: branch,
      occupancy: occupancy ?? this.occupancy,
      bookings: bookings ?? this.bookings,
      payments: payments ?? this.payments,
      reviews: reviews ?? this.reviews,
      loadingDetails: loadingDetails ?? isLoadingDetails,
      loadingShared: loadingShared ?? isLoadingShared,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  int get paidPayments {
    return payments
        .where((item) => item.status == AdminPaymentStatus.paid)
        .length;
  }

  int get waitingPayments {
    return payments
        .where(
          (item) =>
              !item.hasPaymentRecord ||
              item.status == AdminPaymentStatus.pending,
        )
        .length;
  }

  double get monthlyIncome {
    final now = DateTime.now();
    return payments
        .where((item) {
          final date = item.createdDate;
          return item.status == AdminPaymentStatus.paid &&
              date != null &&
              date.month == now.month &&
              date.year == now.year;
        })
        .fold<double>(0, (total, item) => total + item.amountRaw);
  }

  List<AdminReviewItem> get visibleReviews {
    return reviews.where((item) => item.isVisible).toList()..sort((a, b) {
      final first = a.createdDate;
      final second = b.createdDate;
      if (first == null && second == null) return b.id.compareTo(a.id);
      if (first == null) return 1;
      if (second == null) return -1;
      return second.compareTo(first);
    });
  }

  double get averageRating {
    final items = visibleReviews;
    if (items.isEmpty) return 0;
    return items.fold<int>(0, (total, item) => total + item.rating) /
        items.length;
  }
}

class _OwnerBranchDashboardCard extends StatelessWidget {
  const _OwnerBranchDashboardCard({required this.item});

  final _OwnerBranchDashboardItem item;

  @override
  Widget build(BuildContext context) {
    final reviews = item.visibleReviews;
    final latestReview = reviews.isEmpty ? null : reviews.first;
    final loadingAny = item.isLoadingDetails || item.isLoadingShared;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.branch.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: item.branch.isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  item.branch.isActive ? 'Aktif' : 'Nonaktif',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (loadingAny) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.gold,
                backgroundColor: AppColors.white,
              ),
            ),
          ],
          if (item.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              item.errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _OwnerStatGrid(
            items: [
              _OwnerStatItem(
                'Booking',
                item.isLoadingShared ? '...' : '${item.bookings.length}',
                Icons.assignment_rounded,
              ),
              _OwnerStatItem(
                'Pembayaran Valid',
                item.isLoadingShared ? '...' : '${item.paidPayments}',
                Icons.verified_rounded,
              ),
              _OwnerStatItem(
                'Menunggu Bayar',
                item.isLoadingShared ? '...' : '${item.waitingPayments}',
                Icons.hourglass_top_rounded,
              ),
              _OwnerStatItem(
                'Pemasukan Bulan Ini',
                item.isLoadingShared ? '...' : _rupiah(item.monthlyIncome),
                Icons.savings_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          item.isLoadingDetails
              ? const _OwnerMiniLoadingCard(label: 'Memuat review cabang...')
              : _OwnerReviewSummary(
                  average: item.averageRating,
                  total: reviews.length,
                  latest: latestReview,
                  reviews: reviews,
                ),
          const SizedBox(height: 12),
          item.isLoadingDetails
              ? const _OwnerMiniLoadingCard(label: 'Memuat okupansi kamar...')
              : _OwnerOccupancySummary(item: item.occupancy),
        ],
      ),
    );
  }
}

class _OwnerMiniLoadingCard extends StatelessWidget {
  const _OwnerMiniLoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.navy,
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

class _OwnerOccupancySummary extends StatelessWidget {
  const _OwnerOccupancySummary({required this.item});

  final OccupancyItem item;

  @override
  Widget build(BuildContext context) {
    final totalRooms = item.rooms.fold<int>(
      0,
      (total, room) => total + room.total,
    );
    final filledRooms = item.rooms.fold<int>(
      0,
      (total, room) => total + room.filled,
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Okupansi Kamar',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$filledRooms/$totalRooms terisi',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (item.rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'Belum ada tipe kamar.',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else
            for (final room in item.rooms) ...[
              _OwnerOccupancyRow(room: room),
              if (room != item.rooms.last) const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }
}

class _OwnerOccupancyRow extends StatelessWidget {
  const _OwnerOccupancyRow({required this.room});

  final RoomOccupancy room;

  @override
  Widget build(BuildContext context) {
    final total = room.total <= 0 ? 0 : room.total;
    final filled = room.filled.clamp(0, total);
    final value = total == 0 ? 0.0 : filled / total;
    final empty = total - filled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                room.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '$filled terisi • $empty kosong',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.navy.withValues(alpha: .14),
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Total $total kamar',
          style: TextStyle(
            color: AppColors.navy.withValues(alpha: .72),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _OwnerStatGrid extends StatelessWidget {
  const _OwnerStatGrid({required this.items});

  final List<_OwnerStatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.68,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gold, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: AppColors.gold, size: 17),
              const Spacer(),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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

class _OwnerReviewSummary extends StatelessWidget {
  const _OwnerReviewSummary({
    required this.average,
    required this.total,
    required this.latest,
    required this.reviews,
  });

  final double average;
  final int total;
  final AdminReviewItem? latest;
  final List<AdminReviewItem> reviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Column(
                  children: [
                    Text(
                      total == 0 ? '-' : average.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _OwnerStarRow(rating: average),
                    const SizedBox(height: 4),
                    Text(
                      '$total review',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: latest == null
                    ? const Text(
                        'Belum ada review untuk cabang ini.',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latest!.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _OwnerStarRow(rating: latest!.rating.toDouble()),
                          if (latest!.comment.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              latest!.comment,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
          if (reviews.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy, width: 1.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _showAllReviews(context),
                child: const Text(
                  'Lihat Semua Review',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllReviews(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .72,
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
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
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      return _OwnerReviewTile(item: reviews[index]);
                    },
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

class _OwnerReviewTile extends StatelessWidget {
  const _OwnerReviewTile({required this.item});

  final AdminReviewItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
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
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (item.createdAt != '-')
                Text(
                  item.createdAt,
                  style: TextStyle(
                    color: AppColors.navy.withValues(alpha: .68),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _OwnerStarRow(rating: item.rating.toDouble()),
          if (item.comment.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              item.comment,
              style: const TextStyle(
                color: AppColors.navy,
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

class _OwnerStarRow extends StatelessWidget {
  const _OwnerStarRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        final icon = rating >= value
            ? Icons.star_rounded
            : rating > index
            ? Icons.star_half_rounded
            : Icons.star_border_rounded;
        return Icon(icon, color: AppColors.gold, size: 12);
      }),
    );
  }
}

class _OwnerStatItem {
  const _OwnerStatItem(this.label, this.value, this.icon);

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
