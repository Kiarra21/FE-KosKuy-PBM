import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/admin_management_item.dart';
import '../../models/managed_room.dart';
import '../../providers/admin_management_provider.dart';
import '../../widgets/admin_branch_badge.dart';
import '../../widgets/app_top_notification.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'admin_bottom_nav.dart';

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  String _status = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetch();
    });
  }

  Future<void> _fetch() {
    return context.read<AdminManagementProvider>().fetchBookings(
      status: _status,
    );
  }

  Future<void> _approve(AdminBookingItem item) async {
    final room = await _pickRoom(item);
    if (room == null) return;
    if (!mounted) return;
    try {
      await context.read<AdminManagementProvider>().approveBooking(
        item.id,
        roomId: room.id,
        status: _status,
      );
      if (!mounted) return;
      showAppTopNotification(
        context,
        message: 'Booking berhasil diverifikasi.',
      );
    } catch (error) {
      if (!mounted) return;
      showAppTopNotification(context, message: '$error');
    }
  }

  Future<ManagedRoom?> _pickRoom(AdminBookingItem item) async {
    if (item.roomTypeId <= 0) {
      showAppTopNotification(
        context,
        message: 'Tipe kamar booking ini tidak terbaca dari API.',
      );
      return null;
    }
    try {
      final rooms = await context
          .read<AdminManagementProvider>()
          .fetchAvailableRooms(item.roomTypeId);
      if (!mounted) return null;
      if (rooms.isEmpty) {
        showAppTopNotification(
          context,
          message: 'Tidak ada kamar kosong untuk tipe ${item.roomName}.',
        );
        return null;
      }
      return showModalBottomSheet<ManagedRoom>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _RoomPickerSheet(rooms: rooms, roomName: item.roomName);
        },
      );
    } catch (error) {
      if (!mounted) return null;
      showAppTopNotification(context, message: '$error');
      return null;
    }
  }

  Future<void> _cancel(AdminBookingItem item) async {
    final confirmed = await _confirm('Batalkan booking ${item.customerName}?');
    if (!confirmed) return;
    if (!mounted) return;
    try {
      await context.read<AdminManagementProvider>().cancelBooking(
        item.id,
        status: _status,
      );
      if (!mounted) return;
      showAppTopNotification(context, message: 'Booking berhasil dibatalkan.');
    } catch (error) {
      if (!mounted) return;
      showAppTopNotification(context, message: '$error');
    }
  }

  Future<void> _checkOut(AdminBookingItem item) async {
    final confirmed = await _confirm(
      'Selesaikan booking ${item.customerName}? Sistem akan memastikan check-in otomatis lalu mengosongkan kamar.',
    );
    if (!confirmed) return;
    if (!mounted) return;
    try {
      await context.read<AdminManagementProvider>().checkOutBooking(
        item.id,
        status: _status,
        autoCheckIn: !item.hasCheckedIn,
      );
      if (!mounted) return;
      showAppTopNotification(
        context,
        message: 'Booking selesai dan kamar sudah dikosongkan.',
      );
    } catch (error) {
      if (!mounted) return;
      showAppTopNotification(context, message: '$error');
    }
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Lanjutkan'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminManagementProvider>();
    return AppFrame(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(showNotification: false),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Manajemen Booking',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusFilter(
                      value: _status,
                      options: const [
                        _FilterOption('', 'Semua', Icons.layers_rounded),
                        _FilterOption(
                          'pending',
                          'Menunggu',
                          Icons.hourglass_top_rounded,
                        ),
                        _FilterOption(
                          'confirmed',
                          'Confirmed',
                          Icons.verified_rounded,
                        ),
                        _FilterOption(
                          'cancelled',
                          'Dibatalkan',
                          Icons.cancel_rounded,
                        ),
                        _FilterOption(
                          'completed',
                          'Selesai',
                          Icons.task_alt_rounded,
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _status = value);
                        _fetch();
                      },
                    ),
                    const SizedBox(height: 10),
                    const AdminBranchBadge(),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _fetch,
                  child: _BookingContent(
                    loading: provider.loadingBookings,
                    error: provider.bookingError,
                    items: provider.bookings,
                    onRetry: _fetch,
                    onApprove: _approve,
                    onCancel: _cancel,
                    onCheckOut: _checkOut,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AdminBottomNav(selectedIndex: 1),
      ),
    );
  }
}

class _BookingContent extends StatelessWidget {
  const _BookingContent({
    required this.loading,
    required this.error,
    required this.items,
    required this.onRetry,
    required this.onApprove,
    required this.onCancel,
    required this.onCheckOut,
  });

  final bool loading;
  final String? error;
  final List<AdminBookingItem> items;
  final Future<void> Function() onRetry;
  final ValueChanged<AdminBookingItem> onApprove;
  final ValueChanged<AdminBookingItem> onCancel;
  final ValueChanged<AdminBookingItem> onCheckOut;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 80, 12, 22),
        children: [
          Center(
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      );
    }
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 90, 12, 22),
        children: const [
          Center(
            child: Text(
              'Belum ada booking.',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 22),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _BookingCard(
          item: item,
          onApprove: () => onApprove(item),
          onCancel: () => onCancel(item),
          onCheckOut: () => onCheckOut(item),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.item,
    required this.onApprove,
    required this.onCancel,
    required this.onCheckOut,
  });

  final AdminBookingItem item;
  final VoidCallback onApprove;
  final VoidCallback onCancel;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    final actionable = item.status == AdminBookingStatus.pending;
    final canCheckOut = item.canCheckOut;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(9),
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
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Badge(label: item.status.label, color: _bookingColor(item)),
            ],
          ),
          const SizedBox(height: 8),
          _InfoLine(icon: Icons.apartment_rounded, text: item.branchName),
          _InfoLine(
            icon: Icons.bed_rounded,
            text: '${item.roomName} - No. ${item.roomNumber}',
          ),
          _InfoLine(
            icon: Icons.event_available_rounded,
            text: _bookingDateText(item),
          ),
          const SizedBox(height: 5),
          _FlowBox(item: item),
          const SizedBox(height: 8),
          Text(
            item.total,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (actionable) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: onApprove,
                    child: const Text('Verifikasi'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: onCancel,
                    child: const Text('Batalkan'),
                  ),
                ),
              ],
            ),
          ],
          if (canCheckOut) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: AppColors.white,
                ),
                onPressed: onCheckOut,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Check Out & Selesaikan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<_FilterOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      width: double.infinity,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = option.value == value;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onChanged(option.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.navy : AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.navy : AppColors.gold,
                  width: 1.4,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 15,
                    color: selected ? AppColors.gold : AppColors.navy,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    option.label,
                    style: TextStyle(
                      color: selected ? AppColors.white : AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowBox extends StatelessWidget {
  const _FlowBox({required this.item});

  final AdminBookingItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_flowIcon(item), color: AppColors.gold, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.flowTitle,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.flowDescription,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.78),
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _flowIcon(AdminBookingItem item) {
  switch (item.status) {
    case AdminBookingStatus.pending:
      return Icons.hourglass_top_rounded;
    case AdminBookingStatus.confirmed:
      return Icons.meeting_room_rounded;
    case AdminBookingStatus.cancelled:
      return Icons.cancel_rounded;
    case AdminBookingStatus.completed:
      return Icons.task_alt_rounded;
  }
}

class _RoomPickerSheet extends StatelessWidget {
  const _RoomPickerSheet({required this.rooms, required this.roomName});

  final List<ManagedRoom> rooms;
  final String roomName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Kamar $roomName',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.meeting_room_rounded,
                        color: AppColors.gold,
                      ),
                      title: Text(
                        'Kamar No. ${room.number}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: const Text('Kosong dan aktif'),
                      onTap: () => Navigator.of(context).pop(room),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _bookingColor(AdminBookingItem item) {
  switch (item.status) {
    case AdminBookingStatus.pending:
      return AppColors.gold;
    case AdminBookingStatus.confirmed:
      return Colors.green;
    case AdminBookingStatus.cancelled:
      return Colors.red;
    case AdminBookingStatus.completed:
      return AppColors.blue;
  }
}

String _bookingDateText(AdminBookingItem item) {
  if (item.checkIn == '-' && item.checkOut == '-') {
    return 'Tanggal belum tersedia';
  }
  if (item.checkIn == '-') return 'Check out ${item.checkOut}';
  if (item.checkOut == '-') return 'Check in ${item.checkIn}';
  return '${item.checkIn} sampai ${item.checkOut}';
}
