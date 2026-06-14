import 'package:flutter/foundation.dart';

import '../models/kos_item.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';

class CustomerRoomProvider extends ChangeNotifier {
  CustomerRoomProvider({BranchService service = const BranchService()})
    : _service = service;

  final BranchService _service;
  List<KosItem> _items = const [];
  final Map<int, KosItem> _details = {};
  bool _loading = false;
  String? _errorMessage;

  List<KosItem> get items => _items;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  void clear() {
    _items = const [];
    _details.clear();
    _errorMessage = null;
    _loading = false;
    notifyListeners();
  }

  /// Fetch daftar cabang kos (branches) untuk halaman home customer.
  Future<void> fetchRoomTypes({
    String? branchId,
    bool? isActive,
    int page = 1,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final branches = await _service.fetchBranches(page: page);
      _items = branches.map(KosItem.fromBranch).toList();
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Tidak bisa memuat data kos.';
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch detail satu cabang kos berdasarkan ID.
  Future<KosItem> fetchRoomType(int id) async {
    final branch = await _service.fetchBranch(id);
    final item = KosItem.fromBranch(branch);
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
