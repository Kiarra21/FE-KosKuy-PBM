import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/managed_room.dart';
import '../../providers/owner_room_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'owner_bottom_nav.dart';

class OwnerRoomFormScreen extends StatefulWidget {
  const OwnerRoomFormScreen({super.key, required this.roomType, this.room});

  final ManagedRoomType roomType;
  final ManagedRoom? room;

  @override
  State<OwnerRoomFormScreen> createState() => _OwnerRoomFormScreenState();
}

class _OwnerRoomFormScreenState extends State<OwnerRoomFormScreen> {
  late final _number = TextEditingController(text: widget.room?.number);
  late bool _active = widget.room?.isActive ?? true;
  late bool _filled = widget.room?.isFilled ?? false;
  bool _loading = false;

  bool get _editing => widget.room != null;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final number = int.tryParse(_number.text.trim());
    if (number == null) {
      _message('Nomor kamar wajib berupa angka.');
      return;
    }
    setState(() => _loading = true);
    try {
      final room = widget.room;
      if (room == null) {
        await context.read<OwnerRoomProvider>().createRoom(
          roomTypeId: widget.roomType.id,
          number: number,
          isActive: _active,
          isFilled: _filled,
        );
      } else {
        await context.read<OwnerRoomProvider>().updateRoom(
          id: room.id,
          roomTypeId: widget.roomType.id,
          number: number,
          isActive: _active,
          isFilled: _filled,
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
                    Text(
                      _editing ? 'Edit Kamar' : 'Tambah Kamar',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FormLabel('Nomor Kamar'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _number,
                            keyboardType: TextInputType.number,
                            decoration: _fieldDecoration(),
                          ),
                          const SizedBox(height: 10),
                          const _FormLabel('Aktif'),
                          const SizedBox(height: 6),
                          _BooleanControl(
                            value: _active,
                            onChanged: (value) =>
                                setState(() => _active = value),
                          ),
                          const SizedBox(height: 10),
                          const _FormLabel('Status Hunian'),
                          const SizedBox(height: 6),
                          _BooleanControl(
                            value: _filled,
                            falseLabel: 'Kosong',
                            trueLabel: 'Ditempati',
                            onChanged: (value) =>
                                setState(() => _filled = value),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: _loading ? null : _save,
                              child: Text(_loading ? 'Menyimpan...' : 'Simpan'),
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

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.white,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BooleanControl extends StatelessWidget {
  const _BooleanControl({
    required this.value,
    required this.onChanged,
    this.falseLabel = 'Tidak',
    this.trueLabel = 'Ya',
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String falseLabel;
  final String trueLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: value ? AppColors.white : Colors.red,
                side: const BorderSide(color: Colors.red, width: 2),
              ),
              onPressed: () => onChanged(false),
              child: Text(
                falseLabel,
                style: TextStyle(color: value ? Colors.red : AppColors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 36,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                backgroundColor: value ? Colors.green : AppColors.white,
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              onPressed: () => onChanged(true),
              child: Text(
                trueLabel,
                style: TextStyle(color: value ? AppColors.white : Colors.green),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
