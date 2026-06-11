import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

enum AppNotificationType { success, error, info }

void showAppTopNotification(
  BuildContext context, {
  required String message,
  AppNotificationType? type,
  Duration duration = const Duration(milliseconds: 2200),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  final notificationType = type ?? _inferType(message);
  if (overlay == null) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _backgroundColor(notificationType),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) {
      return _AppTopNotificationOverlay(
        message: message,
        type: notificationType,
        duration: duration,
        onDismissed: () {
          if (entry.mounted) entry.remove();
        },
      );
    },
  );
  overlay.insert(entry);
}

AppNotificationType _inferType(String message) {
  final text = message.toLowerCase();
  if (text.contains('berhasil') ||
      text.contains('sukses') ||
      text.contains('tersimpan') ||
      text.contains('ditambahkan') ||
      text.contains('diupdate') ||
      text.contains('diperbarui') ||
      text.contains('ditugaskan') ||
      text.contains('dihapus')) {
    return AppNotificationType.success;
  }
  if (text.contains('gagal') ||
      text.contains('tidak bisa') ||
      text.contains('tidak dapat') ||
      text.contains('error') ||
      text.contains('izin') ||
      text.contains('wajib') ||
      text.contains('belum')) {
    return AppNotificationType.error;
  }
  return AppNotificationType.info;
}

Color _backgroundColor(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.success:
      return const Color(0xFF129B48);
    case AppNotificationType.error:
      return const Color(0xFFD62828);
    case AppNotificationType.info:
      return AppColors.navy;
  }
}

IconData _icon(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.success:
      return Icons.check_circle_rounded;
    case AppNotificationType.error:
      return Icons.error_rounded;
    case AppNotificationType.info:
      return Icons.info_rounded;
  }
}

class _AppTopNotificationOverlay extends StatefulWidget {
  const _AppTopNotificationOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final AppNotificationType type;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_AppTopNotificationOverlay> createState() =>
      _AppTopNotificationOverlayState();
}

class _AppTopNotificationOverlayState extends State<_AppTopNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 210),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.05),
      end: Offset.zero,
    ).animate(curve);
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    if (mounted) {
      await _controller.reverse();
    }
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      top: 0,
      child: SafeArea(
        child: IgnorePointer(
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _opacity,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: _backgroundColor(widget.type),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .18),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(_icon(widget.type), color: AppColors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
