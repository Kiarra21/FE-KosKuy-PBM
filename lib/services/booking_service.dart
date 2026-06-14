import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/auth_session.dart';
import '../models/booking_item.dart';
import 'auth_service.dart';

class BookingService {
  const BookingService({http.Client? client}) : _client = client;

  final http.Client? _client;
  static const path = '/bookings';

  http.Client get client => _client ?? http.Client();

  Future<List<BookingItem>> fetchBookings({int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: {'page': '$page'});
    final response = await _get(uri);
    final body = _decode(response);
    final payload = body['data'];
    final items = payload is Map ? payload['data'] : payload;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => BookingItem.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<BookingItem> createBooking({
    required int roomTypeId,
    required String checkInDate,
    required String checkOutDate,
    String? notes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _post(uri, {
      'room_type_id': roomTypeId,
      'check_in_date': checkInDate,
      'check_out_date': checkOutDate,
      if (notes != null) 'notes': notes,
    });
    final body = _decode(response);
    final payload = body['data'];
    return BookingItem.fromJson((payload is Map ? payload : body).cast<String, dynamic>());
  }

  Future<void> submitPayment({
    required int bookingId,
    required List<int> imageBytes,
    required String filename,
    bool retried = false,
  }) async {
    final token = AuthSessionStore.instance.token;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/payments/submit'),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });
    request.fields['booking_id'] = '$bookingId';
    request.files.add(
      http.MultipartFile.fromBytes(
        'proof_image',
        imageBytes,
        filename: filename,
      ),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401 && !retried) {
      try {
        await const AuthService().refresh();
        return submitPayment(
          bookingId: bookingId,
          imageBytes: imageBytes,
          filename: filename,
          retried: true,
        );
      } catch (_) {
        await AuthSessionStore.instance.clear();
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decode(response);
      throw AuthException(_message(body));
    }
  }

  Future<http.Response> _post(Uri uri, Map<String, dynamic> body, {bool retried = false}) async {
    final response = await client
        .post(
          uri,
          headers: {..._headers(), 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 401 && !retried) {
      try {
        await const AuthService().refresh();
        return _post(uri, body, retried: true);
      } catch (_) {
        await AuthSessionStore.instance.clear();
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _decode(response);
      throw AuthException(_message(decoded));
    }
    return response;
  }

  Future<http.Response> _get(Uri uri, {bool retried = false}) async {
    final response = await client
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 401 && !retried) {
      try {
        await const AuthService().refresh();
        return _get(uri, retried: true);
      } catch (_) {
        await AuthSessionStore.instance.clear();
      }
    }
    if (response.statusCode == 404) {
      throw const AuthException('Endpoint pesanan belum tersedia.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decode(response);
      throw AuthException(_message(body));
    }
    return response;
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
    return 'Tidak bisa memuat data pesanan.';
  }
}
