import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/auth_provider.dart';
import '../routes/role_router.dart';
import '../routes/slide_page_route.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final passwordConfirmation = _confirmPasswordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Nama, email, dan password wajib diisi.');
      return;
    }
    if (password != passwordConfirmation) {
      _showMessage('Konfirmasi password tidak sama.');
      return;
    }
    try {
      final session = await context.read<AuthProvider>().register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return AuthShell(
      logoTop: 56,
      children: [
        AuthTextField(
          controller: _nameController,
          label: 'Nama',
          hint: 'Nama Lengkap',
          icon: Icons.person_rounded,
          textInputAction: TextInputAction.next,
          enabled: !loading,
        ),
        const SizedBox(height: 12),
        AuthTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Email',
          icon: Icons.mail_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !loading,
        ),
        const SizedBox(height: 12),
        AuthTextField(
          controller: _phoneController,
          label: 'Telepon',
          hint: 'Telepon',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          enabled: !loading,
        ),
        const SizedBox(height: 12),
        AuthTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Kata Sandi',
          icon: Icons.lock_rounded,
          obscureText: _hidePassword,
          textInputAction: TextInputAction.next,
          enabled: !loading,
          suffixIcon: _hidePassword
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          onSuffixTap: () => setState(() => _hidePassword = !_hidePassword),
        ),
        const SizedBox(height: 12),
        AuthTextField(
          controller: _confirmPasswordController,
          label: 'Konfirmasi Password',
          hint: 'Konfirmasi Kata Sandi',
          icon: Icons.lock_rounded,
          obscureText: _hideConfirm,
          textInputAction: TextInputAction.done,
          enabled: !loading,
          suffixIcon: _hideConfirm
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          onSuffixTap: () => setState(() => _hideConfirm = !_hideConfirm),
        ),
        const SizedBox(height: 36),
        GoldButton(label: 'Daftar', loading: loading, onTap: _register),
        const SizedBox(height: 12),
        AuthSwitchText(
          text: 'Sudah Punya akun?',
          action: 'Login',
          onTap: loading ? () {} : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
