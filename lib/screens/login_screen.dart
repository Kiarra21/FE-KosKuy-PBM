import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/auth_provider.dart';
import '../routes/role_router.dart';
import '../routes/slide_page_route.dart';
import '../services/auth_service.dart';
import '../widgets/app_top_notification.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password wajib diisi.');
      return;
    }
    try {
      final session = await context.read<AuthProvider>().login(
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        SlidePageRoute(child: RoleRouter.screenFor(session.user.role)),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa terhubung ke server.');
    }
  }

  void _showMessage(String message) {
    showAppTopNotification(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return AuthShell(
      logoTop: 102,
      children: [
        AuthTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Email',
          icon: Icons.mail_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !loading,
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Kata Sandi',
          icon: Icons.lock_rounded,
          obscureText: _hidePassword,
          textInputAction: TextInputAction.done,
          enabled: !loading,
          suffixIcon: _hidePassword
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          onSuffixTap: () => setState(() => _hidePassword = !_hidePassword),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: loading
                ? null
                : () {
                    Navigator.of(context).push(
                      SlidePageRoute(
                        child: ForgotPasswordScreen(
                          initialEmail: _emailController.text.trim(),
                        ),
                      ),
                    );
                  },
            child: const Text(
              'Lupa Password?',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        GoldButton(label: 'Login', loading: loading, onTap: _login),
        const SizedBox(height: 12),
        AuthSwitchText(
          text: 'Belum Punya akun?',
          action: 'Register',
          onTap: loading
              ? () {}
              : () => Navigator.of(
                  context,
                ).push(SlidePageRoute(child: const RegisterScreen())),
        ),
      ],
    );
  }
}
