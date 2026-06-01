import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/facility_item.dart';
import '../../providers/branch_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'owner_bottom_nav.dart';

class OwnerFacilityScreen extends StatefulWidget {
  const OwnerFacilityScreen({super.key});

  @override
  State<OwnerFacilityScreen> createState() => _OwnerFacilityScreenState();
}

class _OwnerFacilityScreenState extends State<OwnerFacilityScreen> {
  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    await context.read<BranchProvider>().fetchFacilities();
  }

  Future<void> _openForm([FacilityItem? item]) async {
    final branchProvider = context.read<BranchProvider>();
    final controller = TextEditingController(text: item?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Tambah Fasilitas' : 'Edit Fasilitas'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama fasilitas'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      if (item == null) {
        await branchProvider.createFacility(name);
      } else {
        await branchProvider.updateFacility(item.id, name);
      }
    } on AuthException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _delete(FacilityItem item) async {
    final branchProvider = context.read<BranchProvider>();
    final confirmed = await _confirm('Hapus fasilitas ${item.name}?');
    if (!confirmed) return;
    try {
      await branchProvider.deleteFacility(item.id);
    } on AuthException catch (error) {
      _message(error.message);
    }
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(message),
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
        ) ??
        false;
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branchProvider = context.watch<BranchProvider>();
    final items = branchProvider.facilities;
    return AppFrame(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Master Fasilitas',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: branchProvider.loading
                          ? null
                          : () => _openForm(),
                      icon: const Icon(
                        Icons.add_circle_rounded,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: branchProvider.loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : RefreshIndicator(
                        color: AppColors.gold,
                        onRefresh: _fetch,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.chair_alt_rounded,
                                  color: AppColors.gold,
                                ),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
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
