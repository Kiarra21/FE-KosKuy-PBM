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
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 354,
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Frame 27
            SizedBox(
              height: 33,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rectangle 78
                Container(
                  width: 72,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4C4C4),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                // Filter
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 22 / 15,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Frame 30
          SizedBox(
            width: double.infinity,
            height: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Khusus Title
                const Text(
                  'Khusus',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 22 / 15,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 10),
                // Frame 35 (types)
                SizedBox(
                  height: 27,
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Frame 31
          SizedBox(
            width: double.infinity,
            height: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Daerah Title
                const Text(
                  'Daerah',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 22 / 15,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 10),
                // Frame 35 (areas)
                SizedBox(
                  height: 59,
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Frame 36
          const SizedBox(height: 33),
          const SizedBox(height: 10),
          // Frame 37 (Terapkan)
          SizedBox(
            width: double.infinity,
            height: 33,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2B3F6C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
              onPressed: () => widget.onApply(_type, _area),
              child: const Text(
                'Terapkan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 22 / 15,
                  color: Color(0xFF2B3F6C),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Frame 38
          const SizedBox(height: 33),
        ],
      ),
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
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppColors.gold,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF2B3F6C),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 22 / 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
