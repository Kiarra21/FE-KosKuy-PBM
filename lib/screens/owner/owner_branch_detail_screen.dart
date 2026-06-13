import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../models/branch_item.dart';
import '../../models/branch_photo_item.dart';
import '../../models/facility_item.dart';
import '../../models/managed_user.dart';
import '../../providers/branch_provider.dart';
import '../../providers/owner_user_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../services/auth_service.dart';
import '../../widgets/branch_map_widget.dart';
import '../../widgets/branch_widgets.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/app_top_notification.dart';
import '../../widgets/photo_source_sheet.dart';
import 'owner_bottom_nav.dart';
import 'owner_branch_form_screen.dart';

class OwnerBranchDetailScreen extends StatefulWidget {
  const OwnerBranchDetailScreen({super.key, required this.item});

  final BranchItem item;

  @override
  State<OwnerBranchDetailScreen> createState() =>
      _OwnerBranchDetailScreenState();
}

class _OwnerBranchDetailScreenState extends State<OwnerBranchDetailScreen> {
  final _picker = ImagePicker();
  bool _loading = false;
  String? _errorMessage;
  BranchItem? _item;

  BranchItem get item => _item ?? widget.item;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (widget.item.id == 0) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final detail = await context.read<BranchProvider>().fetchBranch(
        widget.item.id,
      );
      if (!mounted) return;
      setState(() => _item = detail);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Tidak bisa memuat detail cabang.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showTextDialog(String title, String text) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.navy,
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            text.isEmpty ? '-' : text,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Tutup',
                style: TextStyle(color: AppColors.gold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImageDialog(String title, String imageUrl) {
    if (imageUrl.isEmpty) {
      _showTextDialog(title, 'Data belum tersedia.');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.navy,
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 230,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      'Gambar tidak bisa dimuat',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Tutup',
                style: TextStyle(color: AppColors.gold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openMaps(BranchItem item) async {
    final latitude = double.tryParse(item.latitude);
    final longitude = double.tryParse(item.longitude);
    if (latitude == null || longitude == null) {
      _showTextDialog('Lokasi', 'Koordinat belum tersedia.');
      return;
    }
    final encodedName = Uri.encodeComponent(item.name);
    final googleUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$encodedName',
    );
    final geoUri = Uri.parse('geo:0,0?q=$latitude,$longitude($encodedName)');
    try {
      final openedGoogle = await launchUrl(
        googleUri,
        mode: LaunchMode.externalApplication,
      );
      if (openedGoogle) return;
      final openedGeo = await launchUrl(
        geoUri,
        mode: LaunchMode.externalApplication,
      );
      if (openedGeo) return;
    } catch (_) {}
    if (!mounted) return;
    _showTextDialog('Lokasi', 'Tidak bisa membuka aplikasi Maps.');
  }

  Future<void> _openEdit() async {
    final changed = await Navigator.of(
      context,
    ).push(SlidePageRoute(child: OwnerBranchFormScreen(item: item)));
    if (changed == true) _fetchDetail();
  }

  Future<void> _deleteBranch() async {
    final branchProvider = context.read<BranchProvider>();
    final confirmed = await _confirm(
      'Hapus Cabang',
      'Cabang ini akan dihapus permanen.',
    );
    if (!confirmed) return;
    setState(() => _loading = true);
    try {
      await branchProvider.deleteBranch(item.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final branchProvider = context.read<BranchProvider>();
    final source = await showPhotoSourceSheet(context, title: 'Foto Bangunan');
    if (source == null) return;
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1400,
      imageQuality: 88,
    );
    if (image == null) return;
    setState(() => _loading = true);
    try {
      final bytes = await image.readAsBytes();
      await branchProvider.uploadBranchPhoto(
        branchId: item.id,
        photoBytes: bytes,
        filename: image.name.isEmpty ? 'building.jpg' : image.name,
      );
      await _fetchDetail();
      if (!mounted) return;
      _showMessage('Foto bangunan berhasil ditambahkan.');
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _managePhotos() async {
    final branchProvider = context.read<BranchProvider>();
    final photos = await branchProvider.fetchBranchPhotoItems(item.id);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BranchPhotosSheet(
          photos: photos,
          onUpload: () {
            Navigator.of(context).pop();
            _uploadPhoto();
          },
          onDelete: (photo) async {
            Navigator.of(context).pop();
            final confirmed = await _confirm(
              'Hapus Foto',
              'Foto bangunan ini akan dihapus.',
            );
            if (!confirmed) return;
            await branchProvider.deleteBranchPhoto(item.id, photo.id);
            await _fetchDetail();
          },
          onEditOrder: (photo) async {
            Navigator.of(context).pop();
            final order = await _askPhotoOrder(photo.order);
            if (order == null) return;
            await branchProvider.updateBranchPhotoOrder(
              item.id,
              photo.id,
              order,
            );
            await _fetchDetail();
            _managePhotos();
          },
        );
      },
    );
  }

  Future<int?> _askPhotoOrder(int currentOrder) async {
    final controller = TextEditingController(text: '$currentOrder');
    final order = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Urutan Foto'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Urutan'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value == null || value < 0) return;
                Navigator.of(context).pop(value);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return order;
  }

  Future<void> _manageFacilities() async {
    setState(() => _loading = true);
    try {
      final branchProvider = context.read<BranchProvider>();
      await branchProvider.fetchFacilities();
      final allFacilities = branchProvider.facilities;
      final branchFacilities = await branchProvider.fetchBranchFacilities(
        item.id,
      );
      if (!mounted) return;
      final selectedIds = branchFacilities
          .map((facility) => facility.id)
          .toSet();
      final saved = await showModalBottomSheet<List<int>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return BranchFacilitiesSheet(
            facilities: allFacilities,
            selectedIds: selectedIds,
          );
        },
      );
      if (saved == null) return;
      await branchProvider.syncBranchFacilities(item.id, saved);
      if (!mounted) return;
      _showMessage('Fasilitas cabang berhasil disimpan.');
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _manageAdmins() async {
    setState(() => _loading = true);
    try {
      final ownerUserProvider = context.read<OwnerUserProvider>();
      final results = await Future.wait([
        ownerUserProvider.fetchBranchAdmins(item.id),
        ownerUserProvider.fetchAvailableBranchAdmins(item.id),
      ]);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return BranchAdminsSheet(
            connectedAdmins: results[0],
            availableAdmins: results[1],
            onAssign: (admin) {
              Navigator.of(context).pop();
              _assignAdmin(admin);
            },
            onDetach: (admin) {
              Navigator.of(context).pop();
              _detachAdmin(admin);
            },
          );
        },
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _detachAdmin(ManagedUser admin) async {
    final ownerUserProvider = context.read<OwnerUserProvider>();
    final confirmed = await _confirm(
      'Hapus Admin Cabang',
      '${admin.name} tidak lagi mengelola ${item.name}.',
    );
    if (!confirmed) return;
    setState(() => _loading = true);
    try {
      await ownerUserProvider.detachAdminFromBranch(
        branchId: item.id,
        userId: admin.id,
      );
      if (!mounted) return;
      _showMessage('Admin berhasil dihapus dari cabang.');
      _manageAdmins();
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _assignAdmin(ManagedUser admin) async {
    final ownerUserProvider = context.read<OwnerUserProvider>();
    final confirmed = await _confirm(
      'Tugaskan Admin',
      '${admin.name} akan ditugaskan ke ${item.name}.',
    );
    if (!confirmed) return;
    setState(() => _loading = true);
    try {
      await ownerUserProvider.assignAdminToBranch(
        branchId: item.id,
        userId: admin.id,
      );
      if (!mounted) return;
      _showMessage('Admin berhasil ditugaskan ke cabang.');
      _manageAdmins();
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Lanjutkan'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showAppTopNotification(context, message: message);
  }

  double get _mapLatitude {
    return double.tryParse(item.latitude) ?? -8.1734;
  }

  double get _mapLongitude {
    return double.tryParse(item.longitude) ?? 113.7009;
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = item;
    return AppFrame(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(showNotification: false),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _fetchDetail,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 22),
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.chevron_left_rounded,
                                  color: AppColors.navy,
                                  size: 18,
                                ),
                                Text(
                                  'Kembali',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Detail Cabang',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_loading)
                        const LinearProgressIndicator(color: AppColors.gold),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _loading ? null : _openEdit,
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: _loading ? null : _deleteBranch,
                              icon: const Icon(Icons.delete_rounded, size: 16),
                              label: const Text('Hapus'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: BranchActionButton(
                          label: 'Kelola Admin',
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.white,
                          onTap: _manageAdmins,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            BranchDetailField(
                              label: 'Nama',
                              child: BranchDetailValue(text: currentItem.name),
                            ),
                            const SizedBox(height: 9),
                            BranchDetailField(
                              label: 'Deskripsi',
                              child: BranchDetailValue(
                                text: currentItem.description,
                                minHeight: 132,
                                maxLines: 9,
                              ),
                            ),
                            const SizedBox(height: 9),
                            BranchDetailField(
                              label: 'Alamat',
                              child: Row(
                                children: [
                                  Expanded(
                                    child: BranchDetailValue(
                                      text: currentItem.address,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 92,
                                    height: 34,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF777777,
                                        ),
                                        foregroundColor: AppColors.white,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => _showTextDialog(
                                        'Koordinat',
                                        currentItem.locationLabel,
                                      ),
                                      child: const Text(
                                        'Koordinat',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 9),
                            BranchDetailField(
                              label: 'Map Lokasi',
                              child: Column(
                                children: [
                                  BranchMapWidget(
                                    latitude: _mapLatitude,
                                    longitude: _mapLongitude,
                                    height: 180,
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 34,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.gold,
                                        foregroundColor: AppColors.white,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => _openMaps(currentItem),
                                      child: const Text(
                                        'Buka di Aplikasi Maps',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 9),
                            BranchDetailField(
                              label: 'Telepon',
                              child: BranchDetailValue(text: currentItem.phone),
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                Expanded(
                                  child: BranchActionButton(
                                    label: 'Kelola Fasilitas',
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: AppColors.white,
                                    onTap: _manageFacilities,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: BranchActionButton(
                                    label: 'Kelola Foto',
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: AppColors.white,
                                    onTap: _managePhotos,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                Expanded(
                                  child: BranchDetailField(
                                    label: 'Jumlah Kamar',
                                    child: BranchDetailValue(
                                      text: '${currentItem.totalRooms}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: BranchDetailField(
                                    label: 'Kamar Terisi',
                                    child: BranchDetailValue(
                                      text: '${currentItem.totalGuests}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                Expanded(
                                  child: BranchDetailField(
                                    label: 'Foto Bangunan',
                                    child: BranchActionButton(
                                      label: 'Lihat Foto',
                                      backgroundColor: const Color(0xFF777777),
                                      foregroundColor: AppColors.white,
                                      onTap: () => _showImageDialog(
                                        'Foto Bangunan',
                                        currentItem.photos.isEmpty
                                            ? ''
                                            : currentItem.photos.first,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: BranchDetailField(
                                    label: 'Kode QRIS',
                                    child: BranchActionButton(
                                      label: 'Lihat QRIS',
                                      backgroundColor: const Color(0xFF777777),
                                      foregroundColor: AppColors.white,
                                      onTap: () => _showImageDialog(
                                        'Kode QRIS',
                                        currentItem.qrisCodeUrl,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const OwnerBottomNav(selectedIndex: 1),
      ),
    );
  }
}

class BranchAdminsSheet extends StatelessWidget {
  const BranchAdminsSheet({
    super.key,
    required this.connectedAdmins,
    required this.availableAdmins,
    required this.onAssign,
    required this.onDetach,
  });

  final List<ManagedUser> connectedAdmins;
  final List<ManagedUser> availableAdmins;
  final ValueChanged<ManagedUser> onAssign;
  final ValueChanged<ManagedUser> onDetach;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .68,
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola Admin Cabang',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  const BranchAdminSectionLabel(label: 'Admin Terhubung'),
                  if (connectedAdmins.isEmpty)
                    const BranchAdminEmptyLabel(label: 'Belum ada admin.')
                  else
                    for (final admin in connectedAdmins)
                      BranchAdminTile(
                        admin: admin,
                        label: 'Hapus',
                        backgroundColor: Colors.red,
                        onPressed: () => onDetach(admin),
                      ),
                  const SizedBox(height: 14),
                  const BranchAdminSectionLabel(label: 'Admin Tersedia'),
                  if (availableAdmins.isEmpty)
                    const BranchAdminEmptyLabel(
                      label: 'Tidak ada admin tersedia.',
                    )
                  else
                    for (final admin in availableAdmins)
                      BranchAdminTile(
                        admin: admin,
                        label: 'Tugaskan',
                        backgroundColor: AppColors.gold,
                        onPressed: () => onAssign(admin),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BranchAdminSectionLabel extends StatelessWidget {
  const BranchAdminSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class BranchAdminEmptyLabel extends StatelessWidget {
  const BranchAdminEmptyLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(color: AppColors.white)),
    );
  }
}

class BranchAdminTile extends StatelessWidget {
  const BranchAdminTile({
    super.key,
    required this.admin,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  final ManagedUser admin;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        title: Text(
          admin.name,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(admin.email),
        trailing: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: backgroundColor),
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}

class BranchFacilitiesSheet extends StatefulWidget {
  const BranchFacilitiesSheet({
    super.key,
    required this.facilities,
    required this.selectedIds,
  });

  final List<FacilityItem> facilities;
  final Set<int> selectedIds;

  @override
  State<BranchFacilitiesSheet> createState() => _BranchFacilitiesSheetState();
}

class _BranchFacilitiesSheetState extends State<BranchFacilitiesSheet> {
  late final Set<int> _selectedIds = {...widget.selectedIds};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fasilitas Cabang',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final facility in widget.facilities)
              CheckboxListTile(
                value: _selectedIds.contains(facility.id),
                activeColor: AppColors.gold,
                checkColor: AppColors.navy,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  facility.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedIds.add(facility.id);
                    } else {
                      _selectedIds.remove(facility.id);
                    }
                  });
                },
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.gold),
                onPressed: () {
                  Navigator.of(context).pop(_selectedIds.toList());
                },
                child: const Text('Simpan Fasilitas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BranchPhotosSheet extends StatelessWidget {
  const BranchPhotosSheet({
    super.key,
    required this.photos,
    required this.onUpload,
    required this.onDelete,
    required this.onEditOrder,
  });

  final List<BranchPhotoItem> photos;
  final VoidCallback onUpload;
  final ValueChanged<BranchPhotoItem> onDelete;
  final ValueChanged<BranchPhotoItem> onEditOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Foto Bangunan',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onUpload,
                  icon: const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            if (photos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Belum ada foto bangunan.',
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
              )
            else
              SizedBox(
                height: 210,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(photo.url, fit: BoxFit.cover),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            onPressed: () => onDelete(photo),
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: IconButton(
                            onPressed: () => onEditOrder(photo),
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${photo.order}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
