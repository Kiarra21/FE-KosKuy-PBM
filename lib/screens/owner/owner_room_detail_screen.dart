import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/managed_room.dart';
import '../../providers/owner_room_provider.dart';
import '../../routes/slide_page_route.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'owner_bottom_nav.dart';
import 'owner_room_form_screen.dart';

class OwnerRoomDetailScreen extends StatefulWidget {
  const OwnerRoomDetailScreen({super.key, required this.roomType});

  final ManagedRoomType roomType;

  @override
  State<OwnerRoomDetailScreen> createState() => _OwnerRoomDetailScreenState();
}

class _OwnerRoomDetailScreenState extends State<OwnerRoomDetailScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<ManagedRoom> _items = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final items = await context.read<OwnerRoomProvider>().fetchRooms(
        widget.roomType.id,
      );
      if (!mounted) return;
      setState(() => _items = items);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([ManagedRoom? room]) async {
    final changed = await Navigator.of(context).push(
      SlidePageRoute(
        child: OwnerRoomFormScreen(roomType: widget.roomType, room: room),
      ),
    );
    if (changed == true) _fetch();
  }

  Future<void> _openActions(ManagedRoom room) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          decoration: const BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.gold,
                  ),
                  title: const Text(
                    'Edit Kamar',
                    style: TextStyle(color: AppColors.white),
                  ),
                  onTap: () => Navigator.of(context).pop('edit'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: Colors.red),
                  title: const Text(
                    'Hapus Kamar',
                    style: TextStyle(color: AppColors.white),
                  ),
                  onTap: () => Navigator.of(context).pop('delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == 'edit') _openForm(room);
    if (action == 'delete') _delete(room);
  }

  Future<void> _delete(ManagedRoom room) async {
    final roomProvider = context.read<OwnerRoomProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text('Hapus kamar No. ${room.number}?'),
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
      await roomProvider.deleteRoom(widget.roomType.id, room.id);
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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    const Spacer(),
                    const Text(
                      'Detail Tipe Kamar',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _fetch,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                    children: [
                      _RoomTypeSummary(item: widget.roomType),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Daftar Kamar',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 32,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () => _openForm(),
                              child: const Text('Tambah'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 72),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gold,
                            ),
                          ),
                        )
                      else if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 72),
                          child: Center(
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else if (_items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 72),
                          child: Center(child: Text('Belum ada kamar.')),
                        )
                      else
                        for (final room in _items)
                          _PhysicalRoomTile(
                            item: room,
                            onTap: () => _openActions(room),
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

class _RoomTypeSummary extends StatelessWidget {
  const _RoomTypeSummary({required this.item});

  final ManagedRoomType item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
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
              _Badge(
                label: item.isActive ? 'Aktif' : 'Non Aktif',
                color: item.isActive ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Harga : Rp ${item.price}/hari',
            style: const TextStyle(color: AppColors.white, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            'Luas : ${item.roomSize}m2',
            style: const TextStyle(color: AppColors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PhysicalRoomTile extends StatelessWidget {
  const _PhysicalRoomTile({required this.item, required this.onTap});

  final ManagedRoom item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        minTileHeight: 42,
        contentPadding: const EdgeInsets.symmetric(horizontal: 9),
        title: Text(
          'Kamar No. ${item.number}',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Badge(
              label: item.isFilled ? 'Ditempati' : 'Kosong',
              color: item.isFilled ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 5),
            _Badge(
              label: item.isActive ? 'Aktif' : 'Non Aktif',
              color: item.isActive ? Colors.green : Colors.red,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
