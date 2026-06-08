import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/branch_item.dart';
import '../../models/facility_item.dart';
import '../../models/managed_room.dart';
import '../../providers/branch_provider.dart';
import '../../providers/owner_room_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/photo_source_sheet.dart';
import 'owner_bottom_nav.dart';
import 'owner_room_detail_screen.dart';

class OwnerRoomScreen extends StatefulWidget {
  const OwnerRoomScreen({super.key, required this.branch});

  final BranchItem branch;

  @override
  State<OwnerRoomScreen> createState() => _OwnerRoomScreenState();
}

class _OwnerRoomScreenState extends State<OwnerRoomScreen> {
  final _picker = ImagePicker();
  bool _loading = true;
  List<ManagedRoomType> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetch();
    });
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final items = await context.read<OwnerRoomProvider>().fetchRoomTypes(
        widget.branch.id,
      );
      if (!mounted) return;
      setState(() => _items = items);
    } on AuthException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openTypeForm([ManagedRoomType? item]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return OwnerRoomTypeFormSheet(branchId: widget.branch.id, item: item);
      },
    );
    if (saved == true) _fetch();
  }

  Future<void> _deleteType(ManagedRoomType item) async {
    final roomProvider = context.read<OwnerRoomProvider>();
    if (!await _confirm('Hapus tipe kamar ${item.name}?')) return;
    try {
      await roomProvider.deleteRoomType(widget.branch.id, item.id);
      await _fetch();
    } on AuthException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _uploadPhoto(ManagedRoomType item) async {
    final roomProvider = context.read<OwnerRoomProvider>();
    final source = await showPhotoSourceSheet(context, title: 'Foto Kamar');
    if (source == null) return;
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1400,
      imageQuality: 88,
    );
    if (image == null) return;
    try {
      await roomProvider.uploadRoomTypePhoto(
        roomTypeId: item.id,
        bytes: await image.readAsBytes(),
        filename: image.name.isEmpty ? 'room.jpg' : image.name,
      );
      _message('Foto kamar berhasil ditambahkan.');
      return;
    } on AuthException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _managePhotos(ManagedRoomType item) async {
    final roomProvider = context.read<OwnerRoomProvider>();
    final photos = await roomProvider.fetchRoomTypePhotos(item.id);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return OwnerRoomPhotosSheet(
          photos: photos,
          onUpload: () async {
            Navigator.of(context).pop();
            await _uploadPhoto(item);
            if (mounted) {
              _managePhotos(item);
            }
          },
          onDelete: (photo) async {
            Navigator.of(context).pop();
            await roomProvider.deleteRoomTypePhoto(item.id, photo.id);
            _managePhotos(item);
          },
          onEditOrder: (photo) async {
            Navigator.of(context).pop();
            final order = await _askPhotoOrder(photo.order);
            if (order == null) return;
            await roomProvider.updateRoomTypePhotoOrder(
              item.id,
              photo.id,
              order,
            );
            _managePhotos(item);
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

  Future<void> _openRooms(ManagedRoomType item) async {
    await Navigator.of(
      context,
    ).push(SlidePageRoute(child: OwnerRoomDetailScreen(roomType: item)));
    _fetch();
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
    return AppFrame(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Halaman Kamar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.navy,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Tipe Kamar ${widget.branch.name}',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 34,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: () => _openTypeForm(),
                                      child: const Text('Tambah'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 64),
                                child: Center(
                                  child: Text(
                                    'Belum ada tipe kamar.',
                                    style: TextStyle(color: AppColors.navy),
                                  ),
                                ),
                              )
                            else
                              for (final item in _items)
                                OwnerRoomTypeCard(
                                  item: item,
                                  onEdit: () => _openTypeForm(item),
                                  onDetail: () => _openRooms(item),
                                  onManagePhotos: () => _managePhotos(item),
                                  onDelete: () => _deleteType(item),
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

class OwnerRoomTypeCard extends StatelessWidget {
  const OwnerRoomTypeCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDetail,
    required this.onManagePhotos,
    required this.onDelete,
  });

  final ManagedRoomType item;
  final VoidCallback onEdit;
  final VoidCallback onDetail;
  final VoidCallback onManagePhotos;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OwnerRoomStatusBadge(
                label: item.isActive ? 'Aktif' : 'Non Aktif',
                color: item.isActive ? Colors.green : Colors.red,
              ),
              SizedBox(
                width: 30,
                height: 28,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  color: AppColors.white,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                  onSelected: (value) {
                    if (value == 'photos') onManagePhotos();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'photos', child: Text('Kelola Foto')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Harga : Rp ${item.price}/hari',
            style: const TextStyle(color: AppColors.white, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            'Luas : ${item.roomSize}m2',
            style: const TextStyle(color: AppColors.white, fontSize: 11),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.gold,
                    ),
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: onDetail,
                    child: const Text('Detail'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OwnerRoomStatusBadge extends StatelessWidget {
  const OwnerRoomStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class OwnerRoomTypeFormSheet extends StatefulWidget {
  const OwnerRoomTypeFormSheet({super.key, required this.branchId, this.item});

  final int branchId;
  final ManagedRoomType? item;

  @override
  State<OwnerRoomTypeFormSheet> createState() => _OwnerRoomTypeFormSheetState();
}

class _OwnerRoomTypeFormSheetState extends State<OwnerRoomTypeFormSheet> {
  final _picker = ImagePicker();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _description = TextEditingController(
    text: widget.item?.description,
  );
  late final _price = TextEditingController(
    text: '${widget.item?.price ?? ''}',
  );
  late final _size = TextEditingController(
    text: '${widget.item?.roomSize ?? ''}',
  );
  final _number = TextEditingController();
  late bool _active = widget.item?.isActive ?? true;
  bool _roomActive = true;
  late final Set<int> _facilityIds = {...?widget.item?.facilityIds};
  final List<ManagedRoomPhoto> _existingPhotos = [];
  final List<_PendingRoomPhoto> _photos = [];
  List<FacilityItem> _facilities = const [];
  bool _loading = false;
  bool _loadingFacilities = true;
  bool _loadingPhotos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    await _fetchFacilities();
    if (widget.item != null && mounted) {
      await _fetchExistingPhotos();
    }
  }

  Future<void> _fetchFacilities() async {
    try {
      final branchProvider = context.read<BranchProvider>();
      final roomProvider = context.read<OwnerRoomProvider>();
      await branchProvider.fetchFacilities();
      final facilities = branchProvider.facilities;
      final item = widget.item;
      final selectedFacilities = item == null
          ? const <FacilityItem>[]
          : await roomProvider.fetchRoomTypeFacilities(item.id);
      if (!mounted) return;
      setState(() {
        _facilities = facilities;
        if (item != null) {
          _facilityIds
            ..clear()
            ..addAll(selectedFacilities.map((facility) => facility.id));
        }
      });
    } on AuthException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _loadingFacilities = false);
    }
  }

  Future<void> _fetchExistingPhotos() async {
    final item = widget.item;
    if (item == null) return;
    setState(() => _loadingPhotos = true);
    try {
      final photos = await context.read<OwnerRoomProvider>().fetchRoomTypePhotos(
        item.id,
      );
      if (!mounted) return;
      setState(() {
        _existingPhotos
          ..clear()
          ..addAll(photos);
      });
    } on AuthException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _loadingPhotos = false);
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final photos = <_PendingRoomPhoto>[];
      final source = await showPhotoSourceSheet(
        context,
        title: 'Foto Tipe Kamar',
      );
      if (source == null) return;
      if (source == ImageSource.gallery) {
        final images = await _picker.pickMultiImage(
          maxWidth: 1400,
          imageQuality: 88,
        );
        if (images.isEmpty) return;
        for (final image in images) {
          photos.add(
            _PendingRoomPhoto(
              bytes: await image.readAsBytes(),
              filename: image.name.isEmpty ? 'room.jpg' : image.name,
            ),
          );
        }
      } else {
        final image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1400,
          imageQuality: 88,
        );
        if (image == null) return;
        photos.add(
          _PendingRoomPhoto(
            bytes: await image.readAsBytes(),
            filename: image.name.isEmpty ? 'room.jpg' : image.name,
          ),
        );
      }
      if (!mounted) return;
      setState(() => _photos.addAll(photos));
    } catch (_) {
      _message('Tidak bisa memilih foto kamar.');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _size.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final firstRoomNumber = int.tryParse(_number.text.trim());
    if (_name.text.trim().isEmpty ||
        _description.text.trim().isEmpty ||
        int.tryParse(_price.text) == null ||
        int.tryParse(_size.text) == null ||
        (widget.item == null && firstRoomNumber == null)) {
      _message('Lengkapi data kamar dan isi nomor kamar berupa angka.');
      return;
    }
    final roomProvider = context.read<OwnerRoomProvider>();
    setState(() => _loading = true);
    try {
      final item = widget.item;
      late final ManagedRoomType savedItem;
      if (item == null) {
        savedItem = await roomProvider.createRoomType(
          branchId: widget.branchId,
          name: _name.text.trim(),
          description: _description.text.trim(),
          price: int.parse(_price.text),
          roomSize: int.parse(_size.text),
          isActive: _active,
          facilityIds: _facilityIds.toList(),
        );
        await roomProvider.createRoom(
          roomTypeId: savedItem.id,
          number: firstRoomNumber!,
          isActive: _roomActive,
        );
      } else {
        savedItem = await roomProvider.updateRoomType(
          id: item.id,
          branchId: widget.branchId,
          name: _name.text.trim(),
          description: _description.text.trim(),
          price: int.parse(_price.text),
          roomSize: int.parse(_size.text),
          isActive: _active,
          facilityIds: _facilityIds.toList(),
        );
      }
      for (final photo in _photos) {
        await roomProvider.uploadRoomTypePhoto(
          roomTypeId: savedItem.id,
          bytes: photo.bytes,
          filename: photo.filename,
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
    if (!mounted) return;
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
                  widget.item == null ? 'Tambah Kamar' : 'Edit Tipe Kamar',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                OwnerRoomField(controller: _name, hint: 'Nama'),
                const SizedBox(height: 8),
                OwnerRoomField(controller: _description, hint: 'Deskripsi'),
                const SizedBox(height: 8),
                OwnerRoomField(
                  controller: _price,
                  hint: 'Harga',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                OwnerRoomField(
                  controller: _size,
                  hint: 'Luas kamar',
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  activeThumbColor: AppColors.gold,
                  title: const Text(
                    'Tipe Kamar Aktif',
                    style: TextStyle(color: AppColors.white),
                  ),
                  onChanged: (value) => setState(() => _active = value),
                ),
                if (widget.item == null) ...[
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Unit Kamar Pertama',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OwnerRoomField(
                    controller: _number,
                    hint: 'Nomor kamar',
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _roomActive,
                    activeThumbColor: AppColors.gold,
                    title: const Text(
                      'Unit Kamar Aktif',
                      style: TextStyle(color: AppColors.white),
                    ),
                    onChanged: (value) => setState(() => _roomActive = value),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Status kosong atau terisi otomatis dari booking.',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Fasilitas Kamar',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _loadingFacilities
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        )
                      : _facilities.isEmpty
                      ? const Text(
                          'Belum ada fasilitas master.',
                          style: TextStyle(color: AppColors.white),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _facilities.map((facility) {
                            final selected = _facilityIds.contains(facility.id);
                            return FilterChip(
                              label: Text(facility.name),
                              selected: selected,
                              selectedColor: AppColors.gold,
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    _facilityIds.add(facility.id);
                                  } else {
                                    _facilityIds.remove(facility.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Foto Tipe Kamar',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : _pickPhotos,
                      icon: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                if (_loadingPhotos)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    ),
                  )
                else if (_existingPhotos.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Foto tersimpan',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existingPhotos.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 7),
                      itemBuilder: (context, index) {
                        final photo = _existingPhotos[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            photo.url,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_photos.isNotEmpty)
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 7),
                      itemBuilder: (context, index) {
                        final photo = _photos[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.memory(
                                photo.bytes,
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: InkWell(
                                onTap: _loading
                                    ? null
                                    : () {
                                        setState(() => _photos.removeAt(index));
                                      },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                    ),
                    onPressed: _loading ? null : _save,
                    child: const Text('Simpan'),
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

class _PendingRoomPhoto {
  const _PendingRoomPhoto({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

class OwnerRoomField extends StatelessWidget {
  const OwnerRoomField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

class OwnerRoomPhotosSheet extends StatelessWidget {
  const OwnerRoomPhotosSheet({
    super.key,
    required this.photos,
    required this.onUpload,
    required this.onDelete,
    required this.onEditOrder,
  });

  final List<ManagedRoomPhoto> photos;
  final VoidCallback onUpload;
  final ValueChanged<ManagedRoomPhoto> onDelete;
  final ValueChanged<ManagedRoomPhoto> onEditOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Foto Kamar',
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
            Expanded(
              child: photos.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada foto kamar.',
                        style: TextStyle(color: AppColors.white),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                              child: Image.network(
                                photo.url,
                                fit: BoxFit.cover,
                              ),
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
