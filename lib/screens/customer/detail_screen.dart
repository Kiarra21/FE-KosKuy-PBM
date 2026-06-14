import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_config.dart';
import '../../core/app_colors.dart';
import '../../models/kos_item.dart';
import '../../models/review_item.dart';
import '../../providers/customer_room_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../services/review_service.dart';
import '../../widgets/app_top_notification.dart';
import '../../widgets/branch_map_widget.dart';
import '../../widgets/booking_sheet.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/review_widgets.dart';
import 'booking_history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'review_screen.dart';
import '../../services/room_service.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.item});

  final KosItem item;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _bookingOpen = false;
  bool _loading = false;
  KosItem? _detailItem;
  List<KosItem> _roomTypes = const [];
  KosItem? _selectedRoomType;
  BranchReviewStats? _reviewStats;

  KosItem get _item => _detailItem ?? widget.item;

  double? get _mapLatitude => double.tryParse(_item.latitude);
  double? get _mapLongitude => double.tryParse(_item.longitude);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDetail();
    });
  }

  Future<void> _fetchDetail() async {
    if (!mounted) return;
    if (widget.item.id == 0) return;
    setState(() => _loading = true);

    KosItem? item;
    List<KosItem> roomTypes = const [];

    try {
      item = await context.read<CustomerRoomProvider>().fetchRoomType(
        widget.item.id,
      );
    } catch (_) {}

    if (!mounted) return;

    try {
      roomTypes = await const RoomService().fetchRoomTypes(
        branchId: widget.item.id.toString(),
        isActive: true,
      );
    } catch (_) {}

    BranchReviewStats? reviewStats;
    try {
      reviewStats = await const ReviewService().fetchBranchReviewStats(
        widget.item.id,
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      if (item != null) _detailItem = item;
      _roomTypes = roomTypes;
      _reviewStats = reviewStats;
      _loading = false;
    });
  }

  Future<void> _openMaps() async {
    final latitude = _mapLatitude;
    final longitude = _mapLongitude;
    if (latitude == null || longitude == null) {
      showAppTopNotification(
        context,
        message: 'Koordinat lokasi belum tersedia.',
      );
      return;
    }
    final encodedName = Uri.encodeComponent(_item.name);
    final googleUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
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
    showAppTopNotification(
      context,
      message: 'Tidak bisa membuka aplikasi Maps.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return AppFrame(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.white,
            body: SafeArea(
              child: Column(
                children: [
                  const HomeHeader(),
                  SizedBox(
                    height: 2,
                    child: _loading
                        ? const LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.gold,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        DetailImage(
                          photos: item.photos,
                          imageUrl: item.imageUrl,
                        ),
                        const SizedBox(height: 10),
                        DetailInfoCard(
                          item: item,
                          onOrder: () {
                            if (_roomTypes.isNotEmpty) {
                              setState(() {
                                _selectedRoomType = _roomTypes.firstWhere(
                                  (r) => r.availableRooms > 0,
                                  orElse: () => _roomTypes.first,
                                );
                                _bookingOpen = true;
                              });
                            } else {
                              setState(() {
                                _selectedRoomType = null;
                                _bookingOpen = true;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        BranchLocationPreview(
                          item: item,
                          latitude: _mapLatitude,
                          longitude: _mapLongitude,
                          onTap: _openMaps,
                        ),
                        if (_roomTypes.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Pilihan Tipe Kamar',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._roomTypes.map((roomType) {
                            final isSoldOut = roomType.availableRooms <= 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.navy.withValues(alpha: .12),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.navy.withValues(
                                      alpha: .04,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (roomType.photos.isNotEmpty) ...[
                                    SizedBox(
                                      height: 110,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: roomType.photos.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(width: 8),
                                        itemBuilder: (context, index) {
                                          final photoUrl =
                                              roomType.photos[index];
                                          final cleanUrl =
                                              photoUrl.startsWith('http')
                                              ? photoUrl
                                              : ApiConfig.storageUrl(photoUrl);
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              cleanUrl,
                                              width: 165,
                                              height: 110,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      width: 165,
                                                      height: 110,
                                                      color: const Color(
                                                        0xFFEFEDEA,
                                                      ),
                                                      child: const Icon(
                                                        Icons.bed_rounded,
                                                        color: AppColors.gold,
                                                        size: 32,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ] else ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        roomType.imageUrl,
                                        width: double.infinity,
                                        height: 110,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width: double.infinity,
                                                height: 110,
                                                color: const Color(0xFFEFEDEA),
                                                child: const Icon(
                                                  Icons.bed_rounded,
                                                  color: AppColors.gold,
                                                  size: 32,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          roomType.name,
                                          style: const TextStyle(
                                            color: AppColors.navy,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${roomType.price} /hari',
                                        style: const TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.square_foot,
                                        color: AppColors.gold,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Luas: ${roomType.area}',
                                        style: const TextStyle(
                                          color: AppColors.navy,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        isSoldOut
                                            ? 'Habis'
                                            : 'Sisa ${roomType.availableRooms} Kamar',
                                        style: TextStyle(
                                          color: isSoldOut
                                              ? Colors.red
                                              : Colors.green,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (roomType.description.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      roomType.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.navy.withValues(
                                          alpha: .72,
                                        ),
                                        fontSize: 11,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (roomType.facilities.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: roomType.facilities
                                          .map(
                                            (fac) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.navy
                                                    .withValues(alpha: .06),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                fac,
                                                style: const TextStyle(
                                                  color: AppColors.navy,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 34,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.navy,
                                        foregroundColor: AppColors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: isSoldOut
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedRoomType = roomType;
                                                _bookingOpen = true;
                                              });
                                            },
                                      child: const Text(
                                        'Pesan Tipe Ini',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        if (_reviewStats != null) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Ulasan Pengguna',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ReviewStatsSection(
                            stats: _reviewStats!,
                            showTitle: false,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 36,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.navy,
                                side: const BorderSide(
                                  color: AppColors.navy,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  SlidePageRoute(
                                    child: ReviewScreen(
                                      branchId: widget.item.id,
                                      branchName: item.name,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Lihat Semua Review',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E2E2),
                border: Border.all(color: const Color(0xFF9A9A9A), width: 1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  BottomNavIcon(
                    icon: Icons.home_rounded,
                    selected: true,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        SlidePageRoute(child: const HomeScreen()),
                      );
                    },
                  ),
                  BottomNavIcon(
                    icon: Icons.receipt_long_rounded,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        SlidePageRoute(child: const BookingHistoryScreen()),
                      );
                    },
                  ),
                  BottomNavIcon(
                    icon: Icons.account_circle_rounded,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        SlidePageRoute(child: const ProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          IgnorePointer(
            ignoring: !_bookingOpen,
            child: AnimatedOpacity(
              opacity: _bookingOpen ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: GestureDetector(
                onTap: () => setState(() => _bookingOpen = false),
                child: Container(color: Colors.black.withValues(alpha: .52)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              offset: _bookingOpen ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              child: BookingSheet(
                roomTypes: _roomTypes,
                initialRoomType: _selectedRoomType,
                onClose: () => setState(() => _bookingOpen = false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailImage extends StatefulWidget {
  const DetailImage({super.key, required this.photos, required this.imageUrl});

  final List<String> photos;
  final String imageUrl;

  @override
  State<DetailImage> createState() => _DetailImageState();
}

class _DetailImageState extends State<DetailImage> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Collect all valid photo paths/URLs
    final List<String> displayPhotos = [];

    // Add all branch/room photos
    for (final photo in widget.photos) {
      if (photo.trim().isNotEmpty) {
        displayPhotos.add(photo.trim());
      }
    }

    // Fallback to primary imageUrl if photos is empty
    if (displayPhotos.isEmpty && widget.imageUrl.trim().isNotEmpty) {
      displayPhotos.add(widget.imageUrl.trim());
    }

    // Absolute fallback placeholder
    if (displayPhotos.isEmpty) {
      displayPhotos.add(
        'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=600&q=80',
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 190, // Landscape height matching original design
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: displayPhotos.length,
                  itemBuilder: (context, index) {
                    final photoUrl = displayPhotos[index];
                    final cleanUrl = photoUrl.startsWith('http')
                        ? photoUrl
                        : ApiConfig.storageUrl(photoUrl);

                    return Image.network(
                      cleanUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 600,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFEFEDEA),
                          child: const Icon(
                            Icons.bed_rounded,
                            color: AppColors.gold,
                            size: 58,
                          ),
                        );
                      },
                    );
                  },
                ),
                if (displayPhotos.length > 1) ...[
                  // Left arrow
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (_currentIndex > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: .5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Right arrow
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (_currentIndex < displayPhotos.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: .5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (displayPhotos.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(displayPhotos.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: index == _currentIndex ? 16 : 6,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index == _currentIndex
                      ? AppColors.navy.withValues(alpha: .6)
                      : const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
      ],
    );
  }
}

class DetailInfoCard extends StatelessWidget {
  const DetailInfoCard({super.key, required this.item, required this.onOrder});

  final KosItem item;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                height: 21,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.typeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.type,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          InfoLine(icon: Icons.location_on, text: item.address),
          const SizedBox(height: 5),
          InfoLine(icon: Icons.square_foot, text: item.area),
          const SizedBox(height: 5),
          InfoLine(icon: Icons.directions_walk, text: item.distance),
          const SizedBox(height: 12),
          Text(
            item.description,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 10,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: item.facilities
                .map((facility) => FacilityChip(label: facility))
                .toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'Sisa ${item.availableRooms} Kamar',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onOrder,
              child: const Text(
                'Pesan Sekarang',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BranchLocationPreview extends StatelessWidget {
  const BranchLocationPreview({
    super.key,
    required this.item,
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  final KosItem item;
  final double? latitude;
  final double? longitude;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lat = latitude;
    final lng = longitude;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi Cabang',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: .08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.gold,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (lat != null && lng != null)
                Stack(
                  children: [
                    AbsorbPointer(
                      child: BranchMapWidget(
                        latitude: lat,
                        longitude: lng,
                        height: 178,
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: onTap,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: .86),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              color: AppColors.gold,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Buka Maps',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  height: 116,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: .12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Koordinat lokasi belum tersedia.',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
