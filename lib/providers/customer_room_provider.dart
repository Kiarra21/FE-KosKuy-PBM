import 'package:flutter/foundation.dart';

import '../models/kos_item.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';

class CustomerRoomProvider extends ChangeNotifier {
  CustomerRoomProvider({RoomService service = const RoomService()})
    : _service = service;

  final RoomService _service;
  List<KosItem> _items = const [];
  final Map<int, KosItem> _details = {};
  bool _loading = false;
  String? _errorMessage;

  List<KosItem> get items => _items;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRoomTypes({
    String? branchId,
    bool? isActive,
    int page = 1,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _items = await _service.fetchRoomTypes(
        branchId: branchId,
        isActive: isActive,
        page: page,
      );
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Tidak bisa memuat data kos.';
    } finally {
      _setLoading(false);
    }
  }

  Future<KosItem> fetchRoomType(int id) async {
    final item = await _service.fetchRoomType(id);
    _details[id] = item;
    notifyListeners();
    return item;
  }

  KosItem? detailFor(int id) => _details[id];

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
