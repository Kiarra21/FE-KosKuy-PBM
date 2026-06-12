import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/admin_management_item.dart';
import '../../providers/admin_management_provider.dart';
import '../../widgets/admin_branch_badge.dart';
import '../../widgets/app_top_notification.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'admin_bottom_nav.dart';

class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  String _status = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetch();
    });
  }

  Future<void> _fetch() {
    return context.read<AdminManagementProvider>().fetchPayments(
      status: _status,
    );
  }

  Future<void> _verify(AdminPaymentItem item) async {
    try {
      await context.read<AdminManagementProvider>().verifyPayment(
        item.id,
        status: _status,
      );
      if (!mounted) return;
      showAppTopNotification(
        context,
        message: 'Pembayaran berhasil divalidasi.',
      );
    } catch (error) {
      if (!mounted) return;
      showAppTopNotification(context, message: '$error');
    }
  }

  Future<void> _reject(AdminPaymentItem item) async {
    final reason = await _askRejectReason(item);
    if (reason == null || reason.isEmpty) return;
    if (!mounted) return;
    try {
      await context.read<AdminManagementProvider>().rejectPayment(
        item.id,
        reason: reason,
        status: _status,
      );
      if (!mounted) return;
      showAppTopNotification(context, message: 'Pembayaran berhasil ditolak.');
    } catch (error) {
      if (!mounted) return;
      showAppTopNotification(context, message: '$error');
    }
  }

  Future<String?> _askRejectReason(AdminPaymentItem item) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tolak pembayaran ${item.customerName}?'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alasan penolakan',
              hintText: 'Contoh: bukti blur atau nominal tidak sesuai',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return reason;
  }

  void _openProof(AdminPaymentItem item) {
    if (item.proofUrl.isEmpty) {
      showAppTopNotification(context, message: 'Bukti bayar belum tersedia.');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.navy,
          title: const Text(
            'Bukti Bayar',
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.proofUrl,
              width: 240,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'Bukti bayar tidak bisa dimuat.',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Tutup',
                style: TextStyle(color: AppColors.gold),
              ),
            ),
          ],
        );
      },
    );
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
              const HomeHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Manajemen Pembayaran',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _StatusMenu(
                          value: _status,
                          onChanged: (value) {
                            setState(() => _status = value);
                            _fetch();
                          },
                        ),
                      ],
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
                  child: _PaymentContent(
                    loading: provider.loadingPayments,
                    error: provider.paymentError,
                    items: provider.payments,
                    onRetry: _fetch,
                    onVerify: _verify,
                    onReject: _reject,
                    onOpenProof: _openProof,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AdminBottomNav(selectedIndex: 2),
      ),
    );
  }
}

class _PaymentContent extends StatelessWidget {
  const _PaymentContent({
    required this.loading,
    required this.error,
    required this.items,
    required this.onRetry,
    required this.onVerify,
    required this.onReject,
    required this.onOpenProof,
  });

  final bool loading;
  final String? error;
  final List<AdminPaymentItem> items;
  final Future<void> Function() onRetry;
  final ValueChanged<AdminPaymentItem> onVerify;
  final ValueChanged<AdminPaymentItem> onReject;
  final ValueChanged<AdminPaymentItem> onOpenProof;

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
              'Belum ada pembayaran.',
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
        return _PaymentCard(
          item: item,
          onVerify: () => onVerify(item),
          onReject: () => onReject(item),
          onOpenProof: () => onOpenProof(item),
        );
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.item,
    required this.onVerify,
    required this.onReject,
    required this.onOpenProof,
  });

  final AdminPaymentItem item;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onOpenProof;

  @override
  Widget build(BuildContext context) {
    final actionable = item.status == AdminPaymentStatus.pending;
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
              _Badge(label: item.status.label, color: _paymentColor(item)),
            ],
          ),
          const SizedBox(height: 8),
          _InfoLine(icon: Icons.apartment_rounded, text: item.branchName),
          _InfoLine(icon: Icons.bed_rounded, text: item.roomName),
          _InfoLine(
            icon: Icons.receipt_long_rounded,
            text: 'Booking #${item.bookingId}',
          ),
          if (item.createdAt != '-')
            _InfoLine(icon: Icons.schedule_rounded, text: item.createdAt),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.amount,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenProof,
                icon: const Icon(Icons.image_rounded, size: 16),
                label: const Text('Bukti'),
                style: TextButton.styleFrom(foregroundColor: AppColors.gold),
              ),
            ],
          ),
          if (actionable) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: onVerify,
                    child: const Text('Validasi'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: onReject,
                    child: const Text('Tolak'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        borderRadius: BorderRadius.circular(10),
        items: const [
          DropdownMenuItem(value: '', child: Text('Semua')),
          DropdownMenuItem(value: 'pending', child: Text('Menunggu')),
          DropdownMenuItem(value: 'paid', child: Text('Valid')),
          DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
        ],
        onChanged: (value) => onChanged(value ?? ''),
      ),
    );
  }
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

Color _paymentColor(AdminPaymentItem item) {
  switch (item.status) {
    case AdminPaymentStatus.pending:
      return AppColors.gold;
    case AdminPaymentStatus.paid:
      return Colors.green;
    case AdminPaymentStatus.rejected:
      return Colors.red;
  }
}
