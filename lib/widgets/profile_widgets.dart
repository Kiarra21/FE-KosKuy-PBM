import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/api_config.dart';
import '../core/app_colors.dart';
import '../models/auth_user.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import 'common_widgets.dart';
import 'home_widgets.dart';
import 'photo_source_sheet.dart';

class ProfileShell extends StatefulWidget {
  const ProfileShell({
    super.key,
    required this.bottomNavigationBar,
    required this.onLoggedOut,
  });

  final Widget bottomNavigationBar;
  final void Function(BuildContext context) onLoggedOut;

  @override
  State<ProfileShell> createState() => _ProfileShellState();
}

class _ProfileShellState extends State<ProfileShell> {
  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      await context.read<ProfileProvider>().fetchProfile();
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa memuat profil.');
    }
  }

  Future<void> _logout() async {
    await context.read<ProfileProvider>().logout();
    if (!mounted) return;
    widget.onLoggedOut(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final hasCachedUser = profileProvider.user != null;
    return AppFrame(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(),
              if (profileProvider.loading && hasCachedUser)
                const SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(color: AppColors.gold),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: profileProvider.loading && !hasCachedUser
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        )
                      : ProfileBody(
                          loading: profileProvider.loggingOut,
                          refreshing: profileProvider.loading,
                          onLogout: _logout,
                          onChanged: profileProvider.fetchProfile,
                        ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: widget.bottomNavigationBar,
      ),
    );
  }
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({
    super.key,
    required this.loading,
    required this.refreshing,
    required this.onLogout,
    required this.onChanged,
  });

  final bool loading;
  final bool refreshing;
  final VoidCallback onLogout;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileProvider>().user;
    final name = user?.name.isNotEmpty == true ? user!.name : 'Adika Pratama';
    final phone = user?.phone?.isNotEmpty == true
        ? user!.phone!
        : '081234567890';
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : 'andi@gmail.com';
    final address = user?.address?.isNotEmpty == true ? user!.address! : '-';
    final photo = user?.profilePicture;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(42, 38, 42, 24),
      children: [
        Center(
          child: ClipOval(
            child: photo == null || photo.isEmpty
                ? const ProfileAvatarFallback()
                : Image.network(
                    ApiConfig.storageUrl(photo),
                    width: 86,
                    height: 86,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const ProfileAvatarFallback();
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    EditProfileSheet(user: user, onChanged: onChanged),
              );
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 52),
        ProfileInfoRow(icon: Icons.person_rounded, title: 'Name', value: name),
        const SizedBox(height: 28),
        ProfileInfoRow(
          icon: Icons.phone_in_talk_rounded,
          title: 'Phone',
          value: phone,
        ),
        const SizedBox(height: 28),
        ProfileInfoRow(
          icon: Icons.alternate_email_rounded,
          title: 'Email',
          value: email,
        ),
        const SizedBox(height: 28),
        ProfileInfoRow(
          icon: Icons.location_on_rounded,
          title: 'Address',
          value: address,
        ),
        const SizedBox(height: 46),
        Center(
          child: SizedBox(
            width: 174,
            height: 36,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: loading ? null : onLogout,
              child: loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    )
                  : const Text(
                      'LOGOUT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileAvatarFallback extends StatelessWidget {
  const ProfileAvatarFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      color: AppColors.navy,
      child: const Icon(Icons.person_rounded, color: AppColors.gold, size: 48),
    );
  }
}

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.user,
    required this.onChanged,
  });

  final AuthUser? user;
  final VoidCallback onChanged;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  Uint8List? _photoBytes;
  String? _photoName;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _addressController = TextEditingController(
      text: widget.user?.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      _showMessage('Nama dan email wajib diisi.');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<ProfileProvider>().updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        photoBytes: _photoBytes,
        photoFilename: _photoName,
      );
      if (!mounted) return;
      widget.onChanged();
      Navigator.of(context).pop();
      _showMessage('Profil berhasil diupdate.');
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa update profil.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final source = await showPhotoSourceSheet(context, title: 'Foto Profil');
      if (source == null) return;
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 900,
        imageQuality: 86,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _photoName = image.name.isEmpty ? 'profile_picture.jpg' : image.name;
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa memilih foto.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        decoration: const BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit Profil',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _loading ? null : _pickPhoto,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipOval(
                        child: EditProfileAvatar(
                          user: widget.user,
                          bytes: _photoBytes,
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.navy, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.navy,
                          size: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload Foto',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            EditProfileField(controller: _nameController, hint: 'Nama'),
            const SizedBox(height: 10),
            EditProfileField(controller: _emailController, hint: 'Email'),
            const SizedBox(height: 10),
            EditProfileField(controller: _phoneController, hint: 'Telepon'),
            const SizedBox(height: 10),
            EditProfileField(controller: _addressController, hint: 'Alamat'),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loading
                  ? null
                  : () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => const ChangePasswordDialog(),
                      );
                    },
              child: const Text(
                'Ganti Password',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navy,
                        ),
                      )
                    : const Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileField extends StatelessWidget {
  const EditProfileField({
    super.key,
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class EditProfileAvatar extends StatelessWidget {
  const EditProfileAvatar({super.key, required this.user, required this.bytes});

  final AuthUser? user;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final selectedBytes = bytes;
    if (selectedBytes != null) {
      return Image.memory(
        selectedBytes,
        width: 82,
        height: 82,
        fit: BoxFit.cover,
      );
    }
    final photo = user?.profilePicture;
    if (photo != null && photo.isNotEmpty) {
      return Image.network(
        ApiConfig.storageUrl(photo),
        width: 82,
        height: 82,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const EditProfileAvatarFallback();
        },
      );
    }
    return const EditProfileAvatarFallback();
  }
}

class EditProfileAvatarFallback extends StatelessWidget {
  const EditProfileAvatarFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      color: AppColors.white,
      child: const Icon(Icons.person_rounded, color: AppColors.navy, size: 44),
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_passwordController.text != _confirmController.text) {
      _showMessage('Konfirmasi password tidak sama.');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<ProfileProvider>().updatePassword(
        currentPassword: _currentController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage('Password berhasil diupdate.');
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa update password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text(
        'Ganti Password',
        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PasswordDialogField(
            controller: _currentController,
            hint: 'Password saat ini',
          ),
          const SizedBox(height: 10),
          PasswordDialogField(
            controller: _passwordController,
            hint: 'Password baru',
          ),
          const SizedBox(height: 10),
          PasswordDialogField(
            controller: _confirmController,
            hint: 'Konfirmasi password',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal', style: TextStyle(color: AppColors.white)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.gold),
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.navy,
                  ),
                )
              : const Text(
                  'Simpan',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ],
    );
  }
}

class PasswordDialogField extends StatelessWidget {
  const PasswordDialogField({
    super.key,
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(
        color: AppColors.navy,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.navy, size: 29),
        const SizedBox(width: 28),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
