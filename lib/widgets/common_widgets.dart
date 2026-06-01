import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';

class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 520) return child;
        return ColoredBox(
          color: AppColors.white,
          child: Center(
            child: SizedBox(
              width: 390,
              height: 844,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(42),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class VersionLabel extends StatelessWidget {
  const VersionLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'V 1.0.0',
      style: TextStyle(
        color: AppColors.white,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: .8,
      ),
    );
  }
}

class BottomNavIcon extends StatelessWidget {
  const BottomNavIcon({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.08 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: Icon(
          icon,
          color: selected
              ? AppColors.navy
              : AppColors.navy.withValues(alpha: .62),
          size: 27,
        ),
      ),
    );
  }
}
