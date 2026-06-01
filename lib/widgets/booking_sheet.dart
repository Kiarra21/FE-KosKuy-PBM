import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class BookingSheet extends StatelessWidget {
  const BookingSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 484,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 20),
          const BookingLabel(label: 'Tanggal Check In'),
          const SizedBox(height: 7),
          const DateField(value: '20/05/2026'),
          const SizedBox(height: 14),
          const BookingLabel(label: 'Tanggal Check Out'),
          const SizedBox(height: 7),
          const DateField(value: '20/05/2026'),
          const SizedBox(height: 14),
          const BookingLabel(label: 'Tipe Kamar'),
          const SizedBox(height: 7),
          const RoomTypeOption(
            title: 'Kamar Mandi Dalam',
            subtitle: 'Sisa 5',
            price: 'Rp250.000',
            selected: true,
          ),
          const SizedBox(height: 8),
          const RoomTypeOption(
            title: 'Kamar Mandi Luar',
            subtitle: 'Habis',
            price: 'Rp200.000',
            selected: false,
            soldOut: true,
          ),
          const Spacer(),
          const Row(
            children: [
              Text(
                'Total :',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Spacer(),
              Text(
                'Rp2.500.000',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onClose,
              child: const Text(
                'Pesan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
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
        fontSize: 14,
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
              fontSize: 12,
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
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.white : AppColors.gold,
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
                    color: selected ? AppColors.navy : AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: soldOut ? Colors.red : AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: selected ? AppColors.gold : AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
