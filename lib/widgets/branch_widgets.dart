import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/branch_item.dart';

class BranchCard extends StatelessWidget {
  const BranchCard({
    super.key,
    required this.item,
    required this.onRooms,
    required this.onDetail,
  });

  final BranchItem item;
  final VoidCallback onRooms;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          BranchInfoLine(icon: Icons.location_on_rounded, text: item.address),
          const SizedBox(height: 6),
          BranchInfoLine(icon: Icons.phone_rounded, text: item.phone),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BranchActionButton(
                  label: 'Lihat Kamar',
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.gold,
                  onTap: onRooms,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BranchActionButton(
                  label: 'Detail',
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.white,
                  onTap: onDetail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BranchInfoLine extends StatelessWidget {
  const BranchInfoLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class BranchActionButton extends StatelessWidget {
  const BranchActionButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 32,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BranchDetailField extends StatelessWidget {
  const BranchDetailField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class BranchDetailValue extends StatelessWidget {
  const BranchDetailValue({
    super.key,
    required this.text,
    this.minHeight = 32,
    this.maxLines = 1,
  });

  final String text;
  final double minHeight;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE1E4EA),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text.isEmpty ? '-' : text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 10,
          height: 1.35,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class BranchLoadingState extends StatelessWidget {
  const BranchLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 280,
      child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
    );
  }
}

class BranchEmptyState extends StatelessWidget {
  const BranchEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
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

class BranchErrorState extends StatelessWidget {
  const BranchErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
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
