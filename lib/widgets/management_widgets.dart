import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/occupancy_item.dart';

class OccupancyCard extends StatelessWidget {
  const OccupancyCard({super.key, required this.item, this.compact = false});

  final OccupancyItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 0 : 18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            height: compact ? 38 : 44,
            color: AppColors.gold,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  height: compact ? 20 : 22,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.typeColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.type,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 7 : 10),
            child: Column(
              children: [
                for (final room in item.rooms) ...[
                  RoomOccupancyTile(room: room, compact: compact),
                  if (room != item.rooms.last)
                    SizedBox(height: compact ? 6 : 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoomOccupancyTile extends StatelessWidget {
  const RoomOccupancyTile({
    super.key,
    required this.room,
    required this.compact,
  });

  final RoomOccupancy room;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 40 : 50,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  room.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: compact ? 8 : 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Jumlah : ${room.total} Kamar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: compact ? 8 : 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Terisi : ${room.filled} Kamar',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: compact ? 8 : 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ManagementActionCard extends StatelessWidget {
  const ManagementActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 92,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 52),
              const SizedBox(width: 22),
              Expanded(
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ManagementBottomNav extends StatelessWidget {
  const ManagementBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
  });

  final List<ManagementNavItem> items;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E2),
        border: Border.all(color: const Color(0xFF9A9A9A), width: 1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = selectedIndex == index;
          return GestureDetector(
            onTap: item.onTap,
            child: AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Icon(
                item.icon,
                color: selected
                    ? AppColors.navy
                    : AppColors.navy.withValues(alpha: .62),
                size: 27,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ManagementNavItem {
  const ManagementNavItem({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;
}
