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
