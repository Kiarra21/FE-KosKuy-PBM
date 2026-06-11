import 'package:flutter/material.dart';

class SlidePageRoute extends PageRouteBuilder {
  SlidePageRoute({required Widget child})
    : super(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => child,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: .985, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
}
