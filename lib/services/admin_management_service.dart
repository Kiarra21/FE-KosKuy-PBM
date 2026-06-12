import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/admin_management_item.dart';
import '../models/auth_session.dart';
import '../models/managed_room.dart';
import 'auth_service.dart';

class AdminManagementService {
  const AdminManagementService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  Future<List<AdminBookingItem>> fetchBookings({String? status}) async {
    final items = await _getList(
      '/bookings',
      query: {if (status != null && status.isNotEmpty) 'status': status},
    );
    return items.map(AdminBookingItem.fromJson).toList();
  }

  Future<List<AdminPaymentItem>> fetchPayments({String? status}) async {
    final items = await _getList('/bookings');
    final payments = items.where(_hasPaymentData).map((item) {
      final payment = item['payment'];
      if (payment is Map) {
        return AdminPaymentItem.fromJson(
          payment.cast<String, dynamic>(),
          bookingJson: item,
        );
      }
      return AdminPaymentItem.fromJson(item);
    }).toList();
    if (status == null || status.isEmpty) return payments;
    final expected = AdminPaymentStatus.from(status);
    return payments.where((item) => item.status == expected).toList();
  }

  Future<List<ManagedRoom>> fetchAvailableRooms(int roomTypeId) async {
    final items = await _getList(
      '/rooms',
      query: {
        'room_type_id': '$roomTypeId',
        'is_active': 'true',
        'is_filled': 'false',
      },
    );
    return items.map(ManagedRoom.fromJson).toList();
  }

  Future<void> approveBooking({required int bookingId, required int roomId}) {
    return _json(
      'POST',
      '/bookings/$bookingId/confirm',
      body: {'room_id': roomId},
    );
  }

  Future<void> cancelBooking(int bookingId) {
    return _json('POST', '/bookings/$bookingId/cancel');
  }

  Future<void> checkInBooking(int bookingId) {
    return _json('POST', '/bookings/$bookingId/check-in');
  }

  Future<void> checkOutBooking(int bookingId) {
    return _json('POST', '/bookings/$bookingId/check-out');
  }

  Future<void> verifyPayment(int paymentId) {
    return _json('POST', '/payments/$paymentId/approve');
  }

  Future<void> rejectPayment({required int paymentId, required String reason}) {
    return _json(
      'POST',
      '/payments/$paymentId/reject',
      body: {'rejection_reason': reason},
    );
  }

  bool _hasPaymentData(Map<String, dynamic> item) {
    final payment = item['payment'];
    if (payment is Map && payment.isNotEmpty) return true;
    return item.containsKey('payment_id') ||
        item.containsKey('payment_status') ||
        item.containsKey('proof_image') ||
        item.containsKey('proof_image_url') ||
        item.containsKey('payment_proof') ||
        item.containsKey('payment_proof_url');
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    Map<String, String>? query,
  }) async {
    final items = <Map<String, dynamic>>[];
    var page = 1;
    var lastPage = 1;
    do {
      final response = await _get(path, query: {...?query, 'page': '$page'});
      final body = _decode(response);
      final payload = body['data'];
      final pageItems = payload is Map ? payload['data'] : payload;
      if (pageItems is List) {
        items.addAll(
          pageItems.whereType<Map>().map(
            (item) => item.cast<String, dynamic>(),
          ),
        );
      }
      lastPage = payload is Map ? _intValue(payload['last_page']) : 1;
      page++;
    } while (page <= lastPage);
    return items;
  }

  Future<http.Response> _get(String path, {Map<String, String>? query}) {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: query?.isEmpty == true ? null : query);
    return _request(() => client.get(uri, headers: _headers()));
  }

  Future<void> _json(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    await _request(() {
      final headers = {..._headers(), 'Content-Type': 'application/json'};
      final encoded = body == null ? null : jsonEncode(body);
      if (method == 'POST') {
        return client.post(uri, headers: headers, body: encoded);
      }
      if (method == 'PUT') {
        return client.put(uri, headers: headers, body: encoded);
      }
      return client.patch(uri, headers: headers, body: encoded);
    });
  }

  Future<http.Response> _request(
    Future<http.Response> Function() action, {
    bool retried = false,
  }) async {
    final response = await action().timeout(const Duration(seconds: 15));
    if (response.statusCode == 401 && !retried) {
      await const AuthService().refresh();
      return _request(action, retried: true);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decode(response);
      throw AuthException(_message(body));
    }
    return response;
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('${value ?? ''}') ?? 1;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  Map<String, String> _headers() {
    final token = AuthSessionStore.instance.token;
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String _message(Map<String, dynamic> body) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return '${first.first}';
      return '$first';
    }
    return 'Tidak bisa memuat data admin.';
  }
}
