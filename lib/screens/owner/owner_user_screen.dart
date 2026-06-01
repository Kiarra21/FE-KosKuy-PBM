import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/managed_user.dart';
import '../../providers/branch_provider.dart';
import '../../providers/owner_user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'owner_bottom_nav.dart';

class OwnerUserScreen extends StatefulWidget {
  const OwnerUserScreen({super.key});

  @override
  State<OwnerUserScreen> createState() => _OwnerUserScreenState();
}

class _OwnerUserScreenState extends State<OwnerUserScreen> {
  final _searchController = TextEditingController();
  bool _loading = true;
  List<ManagedUser> _items = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final items = await context.read<OwnerUserProvider>().fetchUsers(
        search: _searchController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _items = items);
    } on AuthException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([ManagedUser? user]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OwnerUserFormSheet(user: user),
    );
    if (saved == true) _fetch();
  }

  Future<void> _delete(ManagedUser user) async {
    final ownerUserProvider = context.read<OwnerUserProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text('Hapus akun ${user.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await ownerUserProvider.deleteUser(user.id);
      await _fetch();
    } on AuthException catch (error) {
      _message(error.message);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            'Manajemen User',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _loading ? null : () => _openForm(),
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _fetch(),
                      decoration: InputDecoration(
                        hintText: 'Cari user',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          onPressed: _fetch,
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF0F1F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : RefreshIndicator(
                        color: AppColors.gold,
                        onRefresh: _fetch,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.email}\n${item.role}${item.role == 'admin' ? '\n${item.branchId == null ? 'Belum terhubung cabang' : 'Branch ID: ${item.branchId}'}' : ''}',
                                ),
                                isThreeLine: item.role == 'admin',
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _openForm(item),
                                      icon: const Icon(Icons.edit_rounded),
                                    ),
                                    IconButton(
                                      onPressed: () => _delete(item),
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const OwnerBottomNav(selectedIndex: 2),
      ),
    );
  }
}

class OwnerUserFormSheet extends StatefulWidget {
  const OwnerUserFormSheet({super.key, this.user});

  final ManagedUser? user;

  @override
  State<OwnerUserFormSheet> createState() => _OwnerUserFormSheetState();
}

class _OwnerUserFormSheetState extends State<OwnerUserFormSheet> {
  late final _nameController = TextEditingController(text: widget.user?.name);
  late final _emailController = TextEditingController(text: widget.user?.email);
  late final _phoneController = TextEditingController(text: widget.user?.phone);
  late final _addressController = TextEditingController(
    text: widget.user?.address,
  );
  final _passwordController = TextEditingController();
  late String _role = widget.user?.role ?? 'admin';
  late int? _branchId = widget.user?.branchId;
  late bool _isActive = widget.user?.isActive ?? true;
  bool _loading = false;

  bool get _editing => widget.user != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchProvider>().fetchBranches();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        (!_editing && _passwordController.text.length < 8)) {
      _message('Nama, email, dan password minimal 8 karakter wajib diisi.');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_editing) {
        await context.read<OwnerUserProvider>().updateUser(
          id: widget.user!.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _role,
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          isActive: _isActive,
          password: _passwordController.text.trim(),
          branchId: _role == 'admin' ? _branchId : null,
        );
      } else {
        await context.read<OwnerUserProvider>().createUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _passwordController.text,
          role: _role,
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          isActive: _isActive,
          branchId: _role == 'admin' ? _branchId : null,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branches = context.watch<BranchProvider>().branches;
    final hasCurrentBranch =
        _branchId != null && branches.every((item) => item.id != _branchId);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        decoration: const BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  _editing ? 'Edit User' : 'Tambah User',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                OwnerUserField(controller: _nameController, hint: 'Nama'),
                const SizedBox(height: 8),
                OwnerUserField(controller: _emailController, hint: 'Email'),
                const SizedBox(height: 8),
                OwnerUserField(controller: _phoneController, hint: 'Telepon'),
                const SizedBox(height: 8),
                OwnerUserField(controller: _addressController, hint: 'Alamat'),
                const SizedBox(height: 8),
                OwnerUserField(
                  controller: _passwordController,
                  hint: _editing ? 'Password baru opsional' : 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  dropdownColor: AppColors.white,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                      value: 'pemilik_kos',
                      child: Text('Pemilik Kos'),
                    ),
                    DropdownMenuItem(
                      value: 'customer',
                      child: Text('Customer'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _role = value ?? _role;
                      if (_role != 'admin') _branchId = null;
                    });
                  },
                ),
                if (_role == 'admin') ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: _branchId,
                    dropdownColor: AppColors.white,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: AppColors.white,
                      labelText: 'Cabang Admin',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tanpa Cabang'),
                      ),
                      if (hasCurrentBranch)
                        DropdownMenuItem<int?>(
                          value: _branchId,
                          child: Text('Cabang ID: $_branchId'),
                        ),
                      for (final branch in branches)
                        DropdownMenuItem<int?>(
                          value: branch.id,
                          child: Text(branch.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _branchId = value),
                  ),
                ],
                SwitchListTile(
                  value: _isActive,
                  activeThumbColor: AppColors.gold,
                  title: const Text(
                    'Akun Aktif',
                    style: TextStyle(color: AppColors.white),
                  ),
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                    ),
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text('Simpan User'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OwnerUserField extends StatelessWidget {
  const OwnerUserField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
