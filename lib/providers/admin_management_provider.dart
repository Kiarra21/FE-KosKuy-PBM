import 'package:flutter/foundation.dart';

import '../models/admin_management_item.dart';
import '../models/auth_session.dart';
import '../models/managed_room.dart';
import '../services/admin_management_service.dart';

class AdminManagementProvider extends ChangeNotifier {
  AdminManagementProvider({
    AdminManagementService service = const AdminManagementService(),
  }) : _service = service;

  final AdminManagementService _service;
  List<AdminBookingItem> _bookings = const [];
  List<AdminPaymentItem> _payments = const [];
  bool _loadingBookings = false;
  bool _loadingPayments = false;
  String? _bookingError;
  String? _paymentError;

  List<AdminBookingItem> get bookings => _bookings;
  List<AdminPaymentItem> get payments => _payments;
  bool get loadingBookings => _loadingBookings;
  bool get loadingPayments => _loadingPayments;
  String? get bookingError => _bookingError;
  String? get paymentError => _paymentError;
  int? get adminBranchId => AuthSessionStore.instance.user?.branchId;

  Future<void> fetchBookings({String? status}) async {
    _loadingBookings = true;
    _bookingError = null;
    notifyListeners();
    try {
      _bookings = await _service.fetchBookings(status: status);
    } catch (error) {
      _bookingError = '$error';
    } finally {
      _loadingBookings = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayments({String? status}) async {
    _loadingPayments = true;
    _paymentError = null;
    notifyListeners();
    try {
      _payments = await _service.fetchPayments(status: status);
    } catch (error) {
      _paymentError = '$error';
    } finally {
      _loadingPayments = false;
      notifyListeners();
    }
  }

  Future<List<ManagedRoom>> fetchAvailableRooms(int roomTypeId) {
    return _service.fetchAvailableRooms(roomTypeId);
  }

  Future<void> approveBooking(
    int bookingId, {
    required int roomId,
    String? status,
  }) async {
    await _service.approveBooking(bookingId: bookingId, roomId: roomId);
    await fetchBookings(status: status);
  }

  Future<void> cancelBooking(int bookingId, {String? status}) async {
    await _service.cancelBooking(bookingId);
    await fetchBookings(status: status);
  }

  Future<void> verifyPayment(int paymentId, {String? status}) async {
    await _service.verifyPayment(paymentId);
    await fetchPayments(status: status);
  }

  Future<void> checkInBooking(int bookingId, {String? status}) async {
    await _service.checkInBooking(bookingId);
    await fetchBookings(status: status);
  }

  Future<void> checkOutBooking(int bookingId, {String? status}) async {
    await _service.checkOutBooking(bookingId);
    await fetchBookings(status: status);
  }

  Future<void> rejectPayment(
    int paymentId, {
    required String reason,
    String? status,
  }) async {
    await _service.rejectPayment(paymentId: paymentId, reason: reason);
    await fetchPayments(status: status);
  }
}
