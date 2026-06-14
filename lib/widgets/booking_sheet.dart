import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/kos_item.dart';
import '../providers/booking_provider.dart';
import '../routes/slide_page_route.dart';
import '../screens/customer/booking_history_screen.dart';

class BookingSheet extends StatefulWidget {
  const BookingSheet({
    super.key,
    required this.roomTypes,
    this.initialRoomType,
    required this.onClose,
  });

  final List<KosItem> roomTypes;
  final KosItem? initialRoomType;
  final VoidCallback onClose;

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  KosItem? _selectedRoomType;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkInDate = DateTime.now();
    _checkOutDate = DateTime.now().add(const Duration(days: 1));
    _selectedRoomType = widget.initialRoomType ??
        (widget.roomTypes.isNotEmpty ? widget.roomTypes.first : null);
  }

  @override
  void didUpdateWidget(covariant BookingSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRoomType != oldWidget.initialRoomType) {
      setState(() {
        _selectedRoomType = widget.initialRoomType;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDateDisplay(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int get _totalNights {
    return _checkOutDate.difference(_checkInDate).inDays;
  }

  double get _totalPrice {
    if (_selectedRoomType == null) return 0;
    return _selectedRoomType!.rawPrice * _totalNights;
  }

  String get _totalPriceFormatted {
    final number = _totalPrice.round();
    if (number == 0) return 'Rp0';
    final text = number.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      final remaining = text.length - index;
      buffer.write(text[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return 'Rp$buffer';
  }

  Future<void> _selectCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navy,
              onPrimary: AppColors.white,
              onSurface: AppColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _checkInDate = picked;
        if (_checkOutDate.isBefore(_checkInDate) ||
            _checkOutDate.isAtSameMomentAs(_checkInDate)) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navy,
              onPrimary: AppColors.white,
              onSurface: AppColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final loading = bookingProvider.loading;

    return Material(
      color: AppColors.navy,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 58,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BookingLabel(label: 'Tanggal Check In'),
                      const SizedBox(height: 7),
                      GestureDetector(
                        onTap: loading ? null : _selectCheckInDate,
                        child: DateField(value: _formatDateDisplay(_checkInDate)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BookingLabel(label: 'Tanggal Check Out'),
                      const SizedBox(height: 7),
                      GestureDetector(
                        onTap: loading ? null : _selectCheckOutDate,
                        child: DateField(value: _formatDateDisplay(_checkOutDate)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const BookingLabel(label: 'Pilih Tipe Kamar'),
            const SizedBox(height: 7),
            if (widget.roomTypes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Tipe kamar tidak tersedia',
                    style: TextStyle(color: AppColors.white, fontSize: 13),
                  ),
                ),
              )
            else ...[
              ...widget.roomTypes.map((type) {
                final isSelected = _selectedRoomType?.id == type.id;
                final isSoldOut = type.availableRooms <= 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GestureDetector(
                    onTap: (loading || isSoldOut)
                        ? null
                        : () {
                            setState(() {
                              _selectedRoomType = type;
                            });
                          },
                    child: RoomTypeOption(
                      title: type.name,
                      subtitle: isSoldOut ? 'Habis' : 'Sisa ${type.availableRooms} Kamar',
                      price: type.price,
                      selected: isSelected,
                      soldOut: isSoldOut,
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            const BookingLabel(label: 'Catatan Tambahan (Opsional)'),
            const SizedBox(height: 6),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _notesController,
                enabled: !loading,
                style: const TextStyle(color: AppColors.navy, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Contoh: Lantai atas, dekat tangga, dsb.',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Total :',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  _totalPriceFormatted,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (loading || _selectedRoomType == null)
                    ? null
                    : () async {
                        final success = await bookingProvider.createBooking(
                          roomTypeId: _selectedRoomType!.id,
                          checkInDate: _formatDateApi(_checkInDate),
                          checkOutDate: _formatDateApi(_checkOutDate),
                          notes: _notesController.text.isNotEmpty
                              ? _notesController.text
                              : null,
                        );
                        if (!context.mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pemesanan berhasil dibuat!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          widget.onClose();
                          Navigator.of(context).pushReplacement(
                            SlidePageRoute(child: const BookingHistoryScreen()),
                          );
                        } else {
                          final err = bookingProvider.errorMessage ??
                              'Gagal membuat pesanan.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navy,
                        ),
                      )
                    : const Text(
                        'Pesan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingLabel extends StatelessWidget {
  const BookingLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: AppColors.gold,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class RoomTypeOption extends StatelessWidget {
  const RoomTypeOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    this.soldOut = false,
  });

  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.gold : AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? AppColors.white : AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: soldOut
                        ? Colors.red
                        : selected
                            ? AppColors.white.withValues(alpha: .8)
                            : AppColors.navy.withValues(alpha: .6),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (selected) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Dipilih',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            price,
            style: TextStyle(
              color: selected ? AppColors.navy : AppColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
