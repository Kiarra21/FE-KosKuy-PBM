import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.initialType,
    required this.initialArea,
    required this.onApply,
  });

  final String? initialType;
  final String? initialArea;
  final void Function(String? type, String? area) onApply;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String? _type = widget.initialType;
  late String? _area = widget.initialArea;

  final List<String> _types = const ['Putra', 'Putri'];
  final List<String> _areas = const [
    'Jl. Sumatra',
    'Jl. Bangka',
    'Jl. Kalimantan',
    'Jl. Riau',
    'Jl. Jawa',
    'Jl. Mastrip',
  ];

  @override
  void didUpdateWidget(covariant FilterSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType ||
        oldWidget.initialArea != widget.initialArea) {
      _type = widget.initialType;
      _area = widget.initialArea;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 342,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Filter',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const FilterSectionTitle(label: 'Khusus'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((type) {
              return SelectableFilterChip(
                label: type,
                selected: _type == type,
                onTap: () {
                  setState(() {
                    _type = _type == type ? null : type;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const FilterSectionTitle(label: 'Daerah'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _areas.map((area) {
              return SelectableFilterChip(
                label: area,
                selected: _area == area,
                onTap: () {
                  setState(() {
                    _area = _area == area ? null : area;
                  });
                },
              );
            }).toList(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => widget.onApply(_type, _area),
              child: const Text(
                'Terapkan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterSectionTitle extends StatelessWidget {
  const FilterSectionTitle({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class SelectableFilterChip extends StatelessWidget {
  const SelectableFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.white : AppColors.gold,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.white.withValues(alpha: .22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
