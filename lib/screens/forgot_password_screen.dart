import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/app_top_notification.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _codeLength = 6;

  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  late final List<TextEditingController> _codeControllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _codeFocusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  int _step = 0;
  bool _hidePassword = true;
  bool _hideConfirm = true;

  String get _email => _emailController.text.trim();
  String get _token => _codeControllers.map((item) => item.text).join();

  @override
  void dispose() {
    _emailController.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _codeFocusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_email.isEmpty) {
      _message('Email wajib diisi.');
      return;
    }
    try {
      final message = await context.read<AuthProvider>().forgotPassword(
        email: _email,
      );
      if (!mounted) return;
      for (final controller in _codeControllers) {
        controller.clear();
      }
      setState(() => _step = 1);
      _message(message);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _codeFocusNodes.first.requestFocus();
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      _message(error.message);
    } catch (_) {
      if (!mounted) return;
      _message('Tidak bisa mengirim kode verifikasi.');
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmation = _confirmController.text;
    if (_token.length != _codeLength || password.isEmpty) {
      _message('Kode dan password wajib diisi.');
      return;
    }
    if (password.length < 8) {
      _message('Password minimal 8 karakter.');
      return;
    }
    if (password != confirmation) {
      _message('Konfirmasi password tidak sama.');
      return;
    }
    try {
      final message = await context.read<AuthProvider>().resetPassword(
        email: _email,
        token: _token,
        password: password,
        passwordConfirmation: confirmation,
      );
      if (!mounted) return;
      _message(message);
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _step = 1);
      _message(error.message);
    } catch (_) {
      if (!mounted) return;
      _message('Tidak bisa mengubah password.');
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.length > 1) {
      _fillPastedCode(value);
      return;
    }
    if (value.isNotEmpty && index < _codeLength - 1) {
      _codeFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _codeFocusNodes[index - 1].requestFocus();
    }
    _openPasswordWhenCodeComplete();
  }

  void _fillPastedCode(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    for (var index = 0; index < _codeLength; index++) {
      _codeControllers[index].text = index < digits.length ? digits[index] : '';
    }
    final nextIndex = digits.length >= _codeLength
        ? _codeLength - 1
        : digits.length;
    _codeFocusNodes[nextIndex.clamp(0, _codeLength - 1)].requestFocus();
    _openPasswordWhenCodeComplete();
  }

  void _openPasswordWhenCodeComplete() {
    if (_token.length != _codeLength) return;
    FocusScope.of(context).unfocus();
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted || _step != 1 || _token.length != _codeLength) return;
      setState(() => _step = 2);
    });
  }

  void _message(String message) {
    showAppTopNotification(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return AuthShell(
      logoTop: _step == 2 ? 34 : 58,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: switch (_step) {
            0 => _ForgotEmailForm(
              key: const ValueKey('email'),
              controller: _emailController,
              loading: loading,
              onSubmit: _sendCode,
            ),
            1 => _VerificationCodeForm(
              key: const ValueKey('code'),
              email: _email,
              controllers: _codeControllers,
              focusNodes: _codeFocusNodes,
              loading: loading,
              onChanged: _onCodeChanged,
              onResend: _sendCode,
              onEditEmail: () => setState(() => _step = 0),
            ),
            _ => _NewPasswordForm(
              key: const ValueKey('password'),
              passwordController: _passwordController,
              confirmController: _confirmController,
              loading: loading,
              hidePassword: _hidePassword,
              hideConfirm: _hideConfirm,
              onTogglePassword: () {
                setState(() => _hidePassword = !_hidePassword);
              },
              onToggleConfirm: () {
                setState(() => _hideConfirm = !_hideConfirm);
              },
              onSubmit: _resetPassword,
              onBackToCode: () => setState(() => _step = 1),
            ),
          },
        ),
        const SizedBox(height: 12),
        AuthSwitchText(
          text: 'Sudah ingat password?',
          action: 'Login',
          onTap: loading ? () {} : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _ForgotEmailForm extends StatelessWidget {
  const _ForgotEmailForm({
    super.key,
    required this.controller,
    required this.loading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Lupa Password',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Masukkan email akun kamu untuk menerima kode verifikasi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        AuthTextField(
          controller: controller,
          label: 'Email',
          hint: 'Email',
          icon: Icons.mail_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          enabled: !loading,
        ),
        const SizedBox(height: 26),
        GoldButton(label: 'Kirim Kode', loading: loading, onTap: onSubmit),
      ],
    );
  }
}

class _VerificationCodeForm extends StatelessWidget {
  const _VerificationCodeForm({
    super.key,
    required this.email,
    required this.controllers,
    required this.focusNodes,
    required this.loading,
    required this.onChanged,
    required this.onResend,
    required this.onEditEmail,
  });

  final String email;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool loading;
  final void Function(int index, String value) onChanged;
  final VoidCallback onResend;
  final VoidCallback onEditEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Kode Verifikasi',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kode sudah dikirim ke $email',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(controllers.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 5,
                right: index == controllers.length - 1 ? 0 : 5,
              ),
              child: SizedBox(
                width: 38,
                height: 44,
                child: TextField(
                  controller: controllers[index],
                  focusNode: focusNodes[index],
                  enabled: !loading,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: index == controllers.length - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.gold,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) => onChanged(index, value),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: loading ? null : onResend,
          child: const Text.rich(
            TextSpan(
              text: 'Tidak mendapatkan email? ',
              children: [
                TextSpan(
                  text: 'Kirim ulang kode',
                  style: TextStyle(color: AppColors.gold),
                ),
              ],
            ),
            style: TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: loading ? null : onEditEmail,
          child: const Text(
            'Ubah email',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _NewPasswordForm extends StatelessWidget {
  const _NewPasswordForm({
    super.key,
    required this.passwordController,
    required this.confirmController,
    required this.loading,
    required this.hidePassword,
    required this.hideConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.onBackToCode,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool loading;
  final bool hidePassword;
  final bool hideConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;
  final VoidCallback onBackToCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Password Baru',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Buat password baru untuk akun kamu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        AuthTextField(
          controller: passwordController,
          label: 'Password Baru',
          hint: 'Password Baru',
          icon: Icons.lock_rounded,
          obscureText: hidePassword,
          suffixIcon: hidePassword
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          onSuffixTap: onTogglePassword,
          textInputAction: TextInputAction.next,
          enabled: !loading,
        ),
        const SizedBox(height: 12),
        AuthTextField(
          controller: confirmController,
          label: 'Konfirmasi Password',
          hint: 'Konfirmasi Password',
          icon: Icons.lock_rounded,
          obscureText: hideConfirm,
          suffixIcon: hideConfirm
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          onSuffixTap: onToggleConfirm,
          textInputAction: TextInputAction.done,
          enabled: !loading,
        ),
        const SizedBox(height: 24),
        GoldButton(label: 'Simpan Password', loading: loading, onTap: onSubmit),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: loading ? null : onBackToCode,
          child: const Text(
            'Ubah kode verifikasi',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
