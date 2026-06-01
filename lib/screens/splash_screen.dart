import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/auth_provider.dart';
import '../routes/role_router.dart';
import '../routes/slide_page_route.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _navigationTimer;
  late final Future<void> _restoreSessionFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: .86,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slide = Tween<Offset>(
      begin: const Offset(0, .28),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _restoreSessionFuture = _restoreSession();
    _navigationTimer = Timer(const Duration(milliseconds: 2400), () {
      _openNextScreen();
    });
  }

  Future<void> _openNextScreen() async {
    await _restoreSessionFuture;
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final session = authProvider.session;
    final screen = authProvider.hasValidSession && session != null
        ? RoleRouter.screenFor(session.user.role)
        : const LoginScreen();
    Navigator.of(context).pushReplacement(SlidePageRoute(child: screen));
  }

  Future<void> _restoreSession() async {
    await context.read<AuthProvider>().restoreAndRefresh();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: ScaleTransition(
                        scale: _scale,
                        child: const LogoMark(size: 162),
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: VersionLabel(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
