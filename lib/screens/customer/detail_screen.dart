import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/kos_item.dart';
import '../../providers/customer_room_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../widgets/booking_sheet.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'booking_history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

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

  KosItem get _item => _detailItem ?? widget.item;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (widget.item.id == 0) return;
    setState(() => _loading = true);
    try {
      final item = await context.read<CustomerRoomProvider>().fetchRoomType(
        widget.item.id,
      );
      if (!mounted) return;
      setState(() => _detailItem = item);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                        DetailImage(imageUrl: item.imageUrl),
                        if (_loading) ...[
                          const SizedBox(height: 8),
                          const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        DetailInfoCard(
                          item: item,
                          onOrder: () => setState(() => _bookingOpen = true),
                        ),
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
                    icon: Icons.grid_view_rounded,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        SlidePageRoute(child: const BookingHistoryScreen()),
                      );
                    },
                  ),
                  BottomNavIcon(
                    icon: Icons.person_rounded,
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
          AnimatedPositioned(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _bookingOpen ? 0 : -510,
            child: BookingSheet(
              onClose: () => setState(() => _bookingOpen = false),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailImage extends StatelessWidget {
  const DetailImage({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            imageUrl,
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 190,
                color: const Color(0xFFEFEDEA),
                child: const Icon(
                  Icons.bed_rounded,
                  color: AppColors.gold,
                  size: 58,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: index == 0 ? 16 : 6,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index == 0
                    ? AppColors.navy.withValues(alpha: .42)
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
