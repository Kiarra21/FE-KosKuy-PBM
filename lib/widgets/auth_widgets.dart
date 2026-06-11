import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'common_widgets.dart';

class AuthShell extends StatefulWidget {
  const AuthShell({super.key, required this.children, required this.logoTop});

  final List<Widget> children;
  final double logoTop;

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;
  late final Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .7, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: .9, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, .72, curve: Curves.easeOutBack),
      ),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, .18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, .72, curve: Curves.easeOutCubic),
          ),
        );
    _formSlide = Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(.18, 1, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: widget.logoTop,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: SlideTransition(
                    position: _logoSlide,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: const LogoMark(size: 142),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 36,
                right: 36,
                top: widget.logoTop + 190,
                child: SlideTransition(
                  position: _formSlide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(children: widget.children),
                  ),
                ),
              ),
              const Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(child: VersionLabel()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.controller,
    this.textInputAction,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.navy.withValues(alpha: .86),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              prefixIcon: Icon(icon, color: AppColors.navy, size: 19),
              suffixIcon: suffixIcon == null
                  ? null
                  : GestureDetector(
                      onTap: onSuffixTap,
                      child: Icon(suffixIcon, color: AppColors.navy, size: 18),
                    ),
              contentPadding: const EdgeInsets.symmetric(vertical: 9),
              filled: true,
              fillColor: const Color(0xFFE8E8E8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppColors.gold, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GoldButton extends StatefulWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.loading ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? .96 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          width: 170,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: .28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.navy,
                  ),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}

class AuthSwitchText extends StatelessWidget {
  const AuthSwitchText({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text.rich(
        TextSpan(
          text: '$text ',
          children: [
            TextSpan(
              text: action,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class RolePreviewButton extends StatelessWidget {
  const RolePreviewButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold, width: 1.2),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
