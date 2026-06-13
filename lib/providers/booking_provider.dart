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

  Future<bool> createBooking({
    required int roomTypeId,
    required String checkInDate,
    required String checkOutDate,
    String? notes,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.createBooking(
        roomTypeId: roomTypeId,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        notes: notes,
      );
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Gagal membuat pesanan.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> submitPayment({
    required int bookingId,
    required List<int> imageBytes,
    required String filename,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.submitPayment(
        bookingId: bookingId,
        imageBytes: imageBytes,
        filename: filename,
      );
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengirim bukti pembayaran.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
