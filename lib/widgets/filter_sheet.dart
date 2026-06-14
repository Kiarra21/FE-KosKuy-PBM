import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.initialType,
    required this.initialArea,
    required this.types,
    required this.areas,
    required this.typeCounts,
    required this.areaCounts,
    required this.onApply,
  });

  final String? initialType;
  final String? initialArea;
  final List<String> types;
  final List<String> areas;
  final Map<String, int> typeCounts;
  final Map<String, int> areaCounts;
  final void Function(String? type, String? area) onApply;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String? _type = widget.initialType;
  late String? _area = widget.initialArea;

  @override
  void didUpdateWidget(covariant FilterSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType ||
        oldWidget.initialArea != widget.initialArea) {
      _type = widget.initialType;
      _area = widget.initialArea;
    }
    if (_type != null && !widget.types.contains(_type)) _type = null;
    if (_area != null && !widget.areas.contains(_area)) _area = null;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .72,
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
        decoration: const BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4C4C4),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filter',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _type = null;
                          _area = null;
                        });
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _FilterSection(
                  title: 'Khusus',
                  emptyLabel: 'Belum ada kategori tersedia.',
                  children: widget.types.map((type) {
                    return SelectableFilterChip(
                      label: type,
                      count: widget.typeCounts[type] ?? 0,
                      selected: _type == type,
                      onTap: () {
                        setState(() {
                          _type = _type == type ? null : type;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                _FilterSection(
                  title: 'Daerah',
                  emptyLabel: 'Belum ada daerah tersedia.',
                  children: widget.areas.map((area) {
                    return SelectableFilterChip(
                      label: area,
                      count: widget.areaCounts[area] ?? 0,
                      selected: _area == area,
                      onTap: () {
                        setState(() {
                          _area = _area == area ? null : area;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2B3F6C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => widget.onApply(_type, _area),
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2B3F6C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.emptyLabel,
    required this.children,
  });

  final String title;
  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 9),
          if (children.isEmpty)
            Text(
              emptyLabel,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: .72),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Wrap(spacing: 6, runSpacing: 7, children: children),
        ],
      ),
    );
  }
}

class SelectableFilterChip extends StatelessWidget {
  const SelectableFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppColors.gold,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2B3F6C),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.gold.withValues(alpha: .22)
                      : Colors.white.withValues(alpha: .58),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Color(0xFF2B3F6C),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
