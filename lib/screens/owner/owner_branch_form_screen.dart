import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/branch_item.dart';
import '../../models/facility_item.dart';
import '../../providers/branch_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/branch_map_widget.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/app_top_notification.dart';
import '../../widgets/photo_source_sheet.dart';
import 'owner_bottom_nav.dart';

class OwnerBranchFormScreen extends StatefulWidget {
  const OwnerBranchFormScreen({super.key, this.item});

  final BranchItem? item;

  @override
  State<OwnerBranchFormScreen> createState() => _OwnerBranchFormScreenState();
}

class _OwnerBranchFormScreenState extends State<OwnerBranchFormScreen> {
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _phoneController = TextEditingController();
  Uint8List? _qrisBytes;
  String? _qrisFilename;
  final List<_PendingBranchPhoto> _buildingPhotos = [];
  final Set<int> _facilityIds = {};
  List<FacilityItem> _facilities = const [];
  bool _loading = false;
  bool _loadingFacilities = true;
  bool _loadingLocation = false;
  String _locationStatus = 'Lokasi belum diambil';
  bool _isActive = true;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _nameController.text = item.name;
      _descriptionController.text = item.description;
      _addressController.text = item.address;
      _longitudeController.text = item.longitude;
      _latitudeController.text = item.latitude;
      _phoneController.text = item.phone;
      _isActive = item.isActive;
      _locationStatus = 'Titik lokasi cabang saat ini';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (item == null) _getCurrentLocation();
      _fetchFacilities();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _longitudeController.dispose();
    _latitudeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickQris() async {
    await _pickImage(
      onPicked: (bytes, filename) {
        setState(() {
          _qrisBytes = bytes;
          _qrisFilename = filename;
        });
      },
      errorMessage: 'Tidak bisa memilih QRIS.',
    );
  }

  Future<void> _fetchFacilities() async {
    try {
      final branchProvider = context.read<BranchProvider>();
      await branchProvider.fetchFacilities();
      final selected = widget.item == null
          ? const <FacilityItem>[]
          : await branchProvider.fetchBranchFacilities(widget.item!.id);
      if (!mounted) return;
      setState(() {
        _facilities = branchProvider.facilities;
        _facilityIds
          ..clear()
          ..addAll(selected.map((facility) => facility.id));
      });
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loadingFacilities = false);
    }
  }

  Future<void> _pickBuildingPhotos() async {
    try {
      final photos = <_PendingBranchPhoto>[];
      final source = await showPhotoSourceSheet(
        context,
        title: 'Foto Bangunan',
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
            _PendingBranchPhoto(
              bytes: await image.readAsBytes(),
              filename: image.name.isEmpty ? 'building.jpg' : image.name,
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
          _PendingBranchPhoto(
            bytes: await image.readAsBytes(),
            filename: image.name.isEmpty ? 'building.jpg' : image.name,
          ),
        );
      }
      if (!mounted) return;
      setState(() => _buildingPhotos.addAll(photos));
    } catch (_) {
      _showMessage('Tidak bisa memilih foto bangunan.');
    }
  }

  Future<void> _pickImage({
    required void Function(Uint8List bytes, String filename) onPicked,
    required String errorMessage,
  }) async {
    try {
      final source = await showPhotoSourceSheet(context, title: 'Pilih Gambar');
      if (source == null) return;
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 88,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      onPicked(bytes, image.name.isEmpty ? 'image.jpg' : image.name);
    } catch (_) {
      _showMessage(errorMessage);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationStatus = 'Mengecek GPS...';
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationStatus = 'GPS belum aktif');
        _showMessage('GPS belum aktif. Nyalakan lokasi dulu.');
        await Geolocator.openLocationSettings();
        return;
      }
      setState(() => _locationStatus = 'Mengecek izin lokasi...');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() => _locationStatus = 'Izin lokasi ditolak');
        _showMessage('Izin lokasi ditolak.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationStatus = 'Izin lokasi diblokir');
        _showMessage(
          'Izin lokasi diblokir. Aktifkan dari pengaturan aplikasi.',
        );
        await Geolocator.openAppSettings();
        return;
      }
      setState(() => _locationStatus = 'Mengambil titik lokasi...');
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        _applyPosition(lastPosition, 'Lokasi sementara dari cache');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 30),
        ),
      );
      _applyPosition(position, 'Lokasi berhasil diambil');
    } on TimeoutException {
      if (!mounted) return;
      setState(
        () => _locationStatus = 'GPS timeout, coba lagi di area terbuka',
      );
      _showMessage('GPS timeout. Coba lagi di area terbuka.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _locationStatus = 'Lokasi gagal diambil');
      _showMessage('Tidak bisa mengambil lokasi: $error');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _applyPosition(Position position, String status) {
    if (!mounted) return;
    setState(() {
      _latitudeController.text = position.latitude.toStringAsFixed(7);
      _longitudeController.text = position.longitude.toStringAsFixed(7);
      _locationStatus = status;
    });
  }

  void _pickMapPoint(LatLng point) {
    setState(() {
      _latitudeController.text = point.latitude.toStringAsFixed(7);
      _longitudeController.text = point.longitude.toStringAsFixed(7);
      _locationStatus = 'Titik lokasi dipilih dari map';
    });
  }

  double get _mapLatitude {
    return double.tryParse(_latitudeController.text) ?? -8.1734;
  }

  double get _mapLongitude {
    return double.tryParse(_longitudeController.text) ?? 113.7009;
  }

  Future<void> _save() async {
    final branchProvider = context.read<BranchProvider>();
    final qrisBytes = _qrisBytes;
    final qrisFilename = _qrisFilename;
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _longitudeController.text.trim().isEmpty ||
        _latitudeController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showMessage('Semua field wajib diisi.');
      return;
    }
    if (!_editing && (qrisBytes == null || qrisFilename == null)) {
      _showMessage('QRIS wajib diupload.');
      return;
    }
    setState(() => _loading = true);
    try {
      final branch = _editing
          ? await branchProvider.updateBranch(
              id: widget.item!.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              address: _addressController.text.trim(),
              longitude: _longitudeController.text.trim(),
              latitude: _latitudeController.text.trim(),
              phone: _phoneController.text.trim(),
              qrisBytes: qrisBytes,
              qrisFilename: qrisFilename,
              isActive: _isActive,
            )
          : await branchProvider.createBranch(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              address: _addressController.text.trim(),
              longitude: _longitudeController.text.trim(),
              latitude: _latitudeController.text.trim(),
              phone: _phoneController.text.trim(),
              qrisBytes: qrisBytes!,
              qrisFilename: qrisFilename!,
              isActive: _isActive,
            );
      await branchProvider.syncBranchFacilities(
        branch.id,
        _facilityIds.toList(),
      );
      for (final photo in _buildingPhotos) {
        await branchProvider.uploadBranchPhoto(
          branchId: branch.id,
          photoBytes: photo.bytes,
          filename: photo.filename,
        );
      }
      if (!mounted) return;
      _showMessage(
        _editing ? 'Cabang berhasil diupdate.' : 'Cabang berhasil ditambahkan.',
      );
      Navigator.of(context).pop(true);
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa tambah cabang.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    showAppTopNotification(context, message: message);
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
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 22),
                  children: [
                    GestureDetector(
                      onTap: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.navy,
                            size: 18,
                          ),
                          const Text(
                            'Kembali',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _editing ? 'Edit Cabang' : 'Tambah Cabang',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          BranchFormField(
                            label: 'Nama',
                            controller: _nameController,
                          ),
                          const SizedBox(height: 10),
                          BranchFormField(
                            label: 'Deskripsi',
                            controller: _descriptionController,
                            maxLines: 5,
                            height: 112,
                          ),
                          const SizedBox(height: 10),
                          BranchFormField(
                            label: 'Alamat',
                            controller: _addressController,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Lokasi GPS',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (_loadingLocation)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.gold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _locationStatus,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          BranchMapWidget(
                            latitude: _mapLatitude,
                            longitude: _mapLongitude,
                            onPicked: _loading ? null : _pickMapPoint,
                            height: 190,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: BranchFormField(
                                  label: 'Latitude',
                                  controller: _latitudeController,
                                  readOnly: true,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: BranchFormField(
                                  label: 'Longitude',
                                  controller: _longitudeController,
                                  readOnly: true,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          BranchFormField(
                            label: 'Telepon',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _loading ? null : _pickQris,
                                  child: Container(
                                    height: 118,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE1E4EA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _qrisBytes == null
                                        ? const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.qr_code_2_rounded,
                                                color: AppColors.navy,
                                                size: 42,
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'Upload QRIS',
                                                style: TextStyle(
                                                  color: AppColors.navy,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Image.memory(
                                            _qrisBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _loading ? null : _pickBuildingPhotos,
                                  child: Container(
                                    height: 118,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE1E4EA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _buildingPhotos.isEmpty
                                        ? const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.apartment_rounded,
                                                color: AppColors.navy,
                                                size: 42,
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'Foto Bangunan',
                                                style: TextStyle(
                                                  color: AppColors.navy,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Image.memory(
                                            _buildingPhotos.first.bytes,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _buildingPhotos.isEmpty
                                  ? 'Belum ada foto bangunan baru'
                                  : '${_buildingPhotos.length} foto bangunan baru dipilih',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (_buildingPhotos.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 68,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _buildingPhotos.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 7),
                                itemBuilder: (context, index) {
                                  final photo = _buildingPhotos[index];
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
                                                  setState(
                                                    () => _buildingPhotos
                                                        .removeAt(index),
                                                  );
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
                          ],
                          const SizedBox(height: 12),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Fasilitas Cabang',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          if (_loadingFacilities)
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
                          else if (_facilities.isEmpty)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Belum ada fasilitas master.',
                                style: TextStyle(color: AppColors.white),
                              ),
                            )
                          else
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _facilities.map((facility) {
                                  final selected = _facilityIds.contains(
                                    facility.id,
                                  );
                                  return FilterChip(
                                    label: Text(facility.name),
                                    selected: selected,
                                    selectedColor: AppColors.gold,
                                    onSelected: _loading
                                        ? null
                                        : (value) {
                                            setState(() {
                                              if (value) {
                                                _facilityIds.add(facility.id);
                                              } else {
                                                _facilityIds.remove(
                                                  facility.id,
                                                );
                                              }
                                            });
                                          },
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppColors.gold,
                            title: const Text(
                              'Status Cabang Aktif',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            value: _isActive,
                            onChanged: _loading
                                ? null
                                : (value) {
                                    setState(() => _isActive = value);
                                  },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
                                  : Text(
                                      _editing
                                          ? 'Update Cabang'
                                          : 'Simpan Cabang',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

class _PendingBranchPhoto {
  const _PendingBranchPhoto({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

class BranchFormField extends StatelessWidget {
  const BranchFormField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.height = 42,
    this.keyboardType,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final double height;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: height,
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFE1E4EA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
