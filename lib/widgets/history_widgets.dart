import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/booking_item.dart';

class HistoryTabBar extends StatelessWidget {
  const HistoryTabBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = ['Berlangsung', 'Lunas', 'Dibatalkan'];
    return Row(
      children: List.generate(tabs.length, (index) {
        final selected = selectedIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.gold : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tabs[index],
                style: TextStyle(
                  color: selected ? AppColors.gold : AppColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class BookingHistoryCard extends StatelessWidget {
  const BookingHistoryCard({
    super.key,
    required this.item,
    required this.status,
    required this.statusColor,
    required this.actionLabel,
    required this.onAction,
    this.cancelled = false,
  });

  final BookingItem item;
  final String status;
  final Color statusColor;
  final String actionLabel;
  final VoidCallback onAction;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.kosName,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'Dibatalkan' ? Colors.red : AppColors.navy,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (cancelled)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Belum Bayar',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else ...[
            Text(
              'Harga Kamar',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.roomLabel,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  item.price,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Total',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '1 Kamar, ${item.durationLabel}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  item.total,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    status == 'Belum Bayar' && item.paymentDeadline.isNotEmpty
                        ? 'Bayar sebelum ${item.paymentDeadline}'
                        : '',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(
                  width: 118,
                  height: 28,
                  child: actionLabel.isEmpty
                      ? const SizedBox.shrink()
                      : FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: onAction,
                          child: Text(
                            actionLabel,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
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

class HistoryLoadingState extends StatelessWidget {
  const HistoryLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
    );
  }
}

class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class HistoryErrorState extends StatelessWidget {
  const HistoryErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 120,
              height: 34,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onRetry,
                child: const Text(
                  'Coba Lagi',
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

class QrCodeBox extends StatelessWidget {
  const QrCodeBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      height: 178,
      padding: const EdgeInsets.all(10),
      color: AppColors.white,
      child: const CustomPaint(painter: QrPainter()),
    );
  }
}

class QrPainter extends CustomPainter {
  const QrPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final cell = size.width / 29;
    final points = <Offset>[
      const Offset(1, 1),
      const Offset(2, 1),
      const Offset(3, 1),
      const Offset(5, 1),
      const Offset(8, 1),
      const Offset(11, 1),
      const Offset(12, 1),
      const Offset(15, 1),
      const Offset(17, 1),
      const Offset(21, 1),
      const Offset(22, 1),
      const Offset(23, 1),
      const Offset(25, 1),
      const Offset(1, 3),
      const Offset(5, 3),
      const Offset(7, 3),
      const Offset(9, 3),
      const Offset(13, 3),
      const Offset(16, 3),
      const Offset(19, 3),
      const Offset(21, 3),
      const Offset(25, 3),
      const Offset(1, 5),
      const Offset(2, 5),
      const Offset(3, 5),
      const Offset(5, 5),
      const Offset(8, 5),
      const Offset(10, 5),
      const Offset(12, 5),
      const Offset(15, 5),
      const Offset(18, 5),
      const Offset(21, 5),
      const Offset(22, 5),
      const Offset(23, 5),
      const Offset(25, 5),
      const Offset(2, 7),
      const Offset(6, 7),
      const Offset(9, 7),
      const Offset(11, 7),
      const Offset(14, 7),
      const Offset(17, 7),
      const Offset(20, 7),
      const Offset(24, 7),
      const Offset(1, 9),
      const Offset(3, 9),
      const Offset(4, 9),
      const Offset(8, 9),
      const Offset(12, 9),
      const Offset(13, 9),
      const Offset(16, 9),
      const Offset(18, 9),
      const Offset(22, 9),
      const Offset(25, 9),
      const Offset(6, 11),
      const Offset(7, 11),
      const Offset(10, 11),
      const Offset(14, 11),
      const Offset(15, 11),
      const Offset(19, 11),
      const Offset(23, 11),
      const Offset(26, 11),
      const Offset(2, 13),
      const Offset(5, 13),
      const Offset(8, 13),
      const Offset(9, 13),
      const Offset(13, 13),
      const Offset(17, 13),
      const Offset(20, 13),
      const Offset(21, 13),
      const Offset(25, 13),
      const Offset(1, 15),
      const Offset(4, 15),
      const Offset(7, 15),
      const Offset(11, 15),
      const Offset(12, 15),
      const Offset(15, 15),
      const Offset(18, 15),
      const Offset(22, 15),
      const Offset(24, 15),
      const Offset(3, 17),
      const Offset(5, 17),
      const Offset(9, 17),
      const Offset(10, 17),
      const Offset(14, 17),
      const Offset(16, 17),
      const Offset(20, 17),
      const Offset(23, 17),
      const Offset(26, 17),
      const Offset(1, 19),
      const Offset(2, 19),
      const Offset(3, 19),
      const Offset(5, 19),
      const Offset(8, 19),
      const Offset(12, 19),
      const Offset(15, 19),
      const Offset(17, 19),
      const Offset(21, 19),
      const Offset(24, 19),
      const Offset(26, 19),
      const Offset(1, 21),
      const Offset(5, 21),
      const Offset(7, 21),
      const Offset(10, 21),
      const Offset(13, 21),
      const Offset(14, 21),
      const Offset(18, 21),
      const Offset(21, 21),
      const Offset(22, 21),
      const Offset(25, 21),
      const Offset(1, 23),
      const Offset(2, 23),
      const Offset(3, 23),
      const Offset(5, 23),
      const Offset(8, 23),
      const Offset(11, 23),
      const Offset(15, 23),
      const Offset(19, 23),
      const Offset(21, 23),
      const Offset(25, 23),
      const Offset(3, 25),
      const Offset(7, 25),
      const Offset(9, 25),
      const Offset(13, 25),
      const Offset(16, 25),
      const Offset(17, 25),
      const Offset(20, 25),
      const Offset(23, 25),
      const Offset(26, 25),
    ];
    for (final point in points) {
      canvas.drawRect(
        Rect.fromLTWH(point.dx * cell, point.dy * cell, cell, cell),
        paint,
      );
    }
    _finder(canvas, paint, cell, const Offset(0, 0));
    _finder(canvas, paint, cell, const Offset(20, 0));
    _finder(canvas, paint, cell, const Offset(0, 20));
  }

  void _finder(Canvas canvas, Paint paint, double cell, Offset offset) {
    canvas.drawRect(
      Rect.fromLTWH(offset.dx * cell, offset.dy * cell, 7 * cell, 7 * cell),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        (offset.dx + 1) * cell,
        (offset.dy + 1) * cell,
        5 * cell,
        5 * cell,
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        (offset.dx + 2) * cell,
        (offset.dy + 2) * cell,
        3 * cell,
        3 * cell,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
