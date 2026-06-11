import 'package:flutter/foundation.dart';

import '../models/booking_item.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider({BookingService service = const BookingService()})
    : _service = service;

  final BookingService _service;
  List<BookingItem> _items = const [];
  bool _loading = false;
  String? _errorMessage;

  List<BookingItem> get items => _items;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBookings({int page = 1}) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _service.fetchBookings(page: page);
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Tidak bisa memuat data pesanan.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
