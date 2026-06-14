import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../widgets/app_top_notification.dart';
import '../../models/booking_item.dart';
import '../../providers/booking_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'booking_history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.booking});

  final BookingItem booking;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  File? _pickedImage;
  bool _uploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.navy),
              title: const Text(
                'Kamera',
                style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.navy),
              title: const Text(
                'Galeri',
                style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    final image = _pickedImage;
    if (image == null) {
      showAppTopNotification(
        context,
        message: 'Pilih bukti pembayaran terlebih dahulu.',
        type: AppNotificationType.error,
      );
      return;
    }

    setState(() => _uploading = true);

    final bytes = await image.readAsBytes();
    final filename = image.path.split(Platform.pathSeparator).last;

    if (!mounted) return;

    final success = await context.read<BookingProvider>().submitPayment(
      bookingId: widget.booking.id,
      imageBytes: bytes,
      filename: filename,
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (success) {
      showAppTopNotification(
        context,
        message: 'Bukti pembayaran berhasil dikirim!',
        type: AppNotificationType.success,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          SlidePageRoute(child: const BookingHistoryScreen()),
          (route) => false,
        );
      }
    } else {
      final err = context.read<BookingProvider>().errorMessage;
      showAppTopNotification(
        context,
        message: err ?? 'Gagal mengirim bukti pembayaran.',
        type: AppNotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return AppFrame(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.navy,
                            size: 18,
                          ),
                          Text(
                            'Kembali',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PaymentCard(booking: booking),
                    const SizedBox(height: 14),
                    if (booking.isUnpaid)
                      _UploadSection(
                        pickedImage: _pickedImage,
                        uploading: _uploading,
                        onPickImage: _showImageSourceOptions,
                        onSubmit: _submitPayment,
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.navy,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Status Saat Ini:\n${booking.status}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
                  Navigator.of(context).pushAndRemoveUntil(
                    SlidePageRoute(child: const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
              BottomNavIcon(
                icon: Icons.receipt_long_rounded,
                selected: true,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const BookingHistoryScreen()),
                  );
                },
              ),
              BottomNavIcon(
                icon: Icons.account_circle_rounded,
                selected: false,
                onTap: () {
                  Navigator.of(context).push(
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

// ──────────────────────────────────────────
// Payment Card — info pemesanan + QRIS
// ──────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.booking});

  final BookingItem booking;

  @override
  Widget build(BuildContext context) {
    final hasQris = booking.qrisCodeUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                booking.kosName,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            booking.roomLabel,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // QRIS
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: hasQris
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        booking.qrisCodeUrl,
                        width: 190,
                        height: 190,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            width: 190,
                            height: 190,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.gold,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const _QrisFallback(),
                      ),
                    )
                  : const _QrisFallback(),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Scan QRIS & masukkan nominal sesuai tagihan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 9,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Rincian
          const _Divider(),
          const SizedBox(height: 10),
          _InfoRow(label: 'Check-in', value: booking.checkInDate),
          const SizedBox(height: 4),
          _InfoRow(label: 'Check-out', value: booking.checkOutDate),
          const SizedBox(height: 4),
          _InfoRow(label: 'Durasi', value: booking.durationLabel),
          const SizedBox(height: 4),
          _InfoRow(label: 'Harga/malam', value: booking.price),
          const SizedBox(height: 10),
          const _Divider(),
          const SizedBox(height: 10),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                booking.total,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          // Catatan
          if (booking.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan: ${booking.notes}',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: .7),
                fontSize: 9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Upload Section — pilih & kirim bukti
// ──────────────────────────────────────────

class _UploadSection extends StatelessWidget {
  const _UploadSection({
    required this.pickedImage,
    required this.uploading,
    required this.onPickImage,
    required this.onSubmit,
  });

  final File? pickedImage;
  final bool uploading;
  final VoidCallback onPickImage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Bukti Pembayaran',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih foto bukti transfer dari galeri kamu.',
            style: TextStyle(
              color: AppColors.navy.withValues(alpha: .55),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Preview / pilih gambar
          GestureDetector(
            onTap: uploading ? null : onPickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: pickedImage != null ? 200 : 110,
              decoration: BoxDecoration(
                color: pickedImage != null
                    ? Colors.transparent
                    : AppColors.navy.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: pickedImage != null
                      ? AppColors.gold
                      : AppColors.navy.withValues(alpha: .2),
                  width: 1.5,
                ),
              ),
              child: pickedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.file(
                        pickedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          color: AppColors.navy.withValues(alpha: .35),
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap untuk pilih foto',
                          style: TextStyle(
                            color: AppColors.navy.withValues(alpha: .45),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (pickedImage != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: uploading ? null : onPickImage,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 13, color: AppColors.navy.withValues(alpha: .5)),
                  const SizedBox(width: 4),
                  Text(
                    'Ganti foto',
                    style: TextStyle(
                      color: AppColors.navy.withValues(alpha: .5),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Tombol kirim
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: uploading ? AppColors.navy.withValues(alpha: .4) : AppColors.gold,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: uploading ? null : onSubmit,
              child: uploading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Kirim Bukti Pembayaran',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Helper Widgets
// ──────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: .65),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.white.withValues(alpha: .15),
      height: 1,
      thickness: 1,
    );
  }
}

class _QrisFallback extends StatelessWidget {
  const _QrisFallback();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 190,
      height: 190,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.navy),
            SizedBox(height: 6),
            Text(
              'QRIS tidak tersedia',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
