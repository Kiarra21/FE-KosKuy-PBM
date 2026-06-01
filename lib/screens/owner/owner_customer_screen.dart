import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/managed_user.dart';
import '../../providers/owner_user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'owner_bottom_nav.dart';

class OwnerCustomerScreen extends StatefulWidget {
  const OwnerCustomerScreen({super.key});

  @override
  State<OwnerCustomerScreen> createState() => _OwnerCustomerScreenState();
}

class _OwnerCustomerScreenState extends State<OwnerCustomerScreen> {
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
      final items = await context.read<OwnerUserProvider>().fetchCustomers(
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

  Future<void> _updateStatus(ManagedUser user, bool value) async {
    try {
      await context.read<OwnerUserProvider>().updateCustomerStatus(
        user.id,
        value,
      );
      await _fetch();
    } on AuthException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _showDetail(ManagedUser user) async {
    try {
      final item = await context.read<OwnerUserProvider>().fetchCustomer(
        user.id,
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(item.name),
            content: Text(
              'Email: ${item.email}\n'
              'Telepon: ${item.phone.isEmpty ? '-' : item.phone}\n'
              'Alamat: ${item.address.isEmpty ? '-' : item.address}\n'
              'Status: ${item.isActive ? 'Aktif' : 'Nonaktif'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );
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
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Customer',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _fetch(),
                      decoration: InputDecoration(
                        hintText: 'Cari customer',
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
                              child: SwitchListTile(
                                activeThumbColor: AppColors.gold,
                                value: item.isActive,
                                onChanged: (value) =>
                                    _updateStatus(item, value),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.email}\n${item.phone.isEmpty ? '-' : item.phone}',
                                ),
                                secondary: IconButton(
                                  onPressed: () => _showDetail(item),
                                  icon: const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.navy,
                                  ),
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
        bottomNavigationBar: const OwnerBottomNav(selectedIndex: 3),
      ),
    );
  }
}
