import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../models/auth_session.dart';
import '../../models/review_item.dart';
import '../../services/auth_service.dart';

class ReviewService {
  const ReviewService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  Future<ReviewItem> submitReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    final body = {
      'booking_id': bookingId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment,
    };
    http.Response response;
    try {
      response = await _post(Uri.parse('${ApiConfig.baseUrl}/reviews'), body);
    } on AuthException catch (error) {
      if (!_shouldTryBookingReviewEndpoint(error.message)) rethrow;
      response = await _postWithFallbacks(bookingId, body, error);
    }
    final responseBody = _decode(response);
    final payload = responseBody['data'];
    return ReviewItem.fromJson(
      (payload is Map ? payload : responseBody).cast<String, dynamic>(),
    );
  }

  Future<http.Response> _postWithFallbacks(
    int bookingId,
    Map<String, dynamic> body,
    AuthException firstError,
  ) async {
    AuthException lastError = firstError;
    final nestedBody = Map<String, dynamic>.from(body)..remove('booking_id');
    final attempts = [
      ('/bookings/$bookingId/reviews', nestedBody),
      ('/bookings/$bookingId/review', nestedBody),
      ('/bookings/$bookingId/reviews', body),
      ('/bookings/$bookingId/review', body),
    ];
    for (final attempt in attempts) {
      try {
        return await _post(
          Uri.parse('${ApiConfig.baseUrl}${attempt.$1}'),
          attempt.$2,
        );
      } on AuthException catch (error) {
        lastError = error;
      }
    }
    if (_shouldTryBookingReviewEndpoint(firstError.message)) {
      throw AuthException(_reviewAccessMessage(firstError.message));
    }
    throw AuthException(_reviewAccessMessage(lastError.message));
  }

  bool _shouldTryBookingReviewEndpoint(String message) {
    final text = message.toLowerCase();
    return text.contains('akses') ||
        text.contains('access') ||
        text.contains('forbidden') ||
        text.contains('unauthorized') ||
        text.contains('tidak ditemukan') ||
        text.contains('not found') ||
        text.contains('route') ||
        text.contains('endpoint');
  }

  String _reviewAccessMessage(String message) {
    final text = message.toLowerCase();
    if (text.contains('akses') ||
        text.contains('access') ||
        text.contains('forbidden') ||
        text.contains('unauthorized')) {
      return 'Ulasan hanya bisa dikirim oleh customer pemilik pesanan yang sudah selesai.';
    }
    return message;
  }

  Future<BranchReviewStats> fetchBranchReviewStats(int branchId) async {
    final reviews = <ReviewItem>[];
    BranchReviewStats? apiStats;
    var page = 1;
    var lastPage = 1;
    do {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/branches/$branchId/reviews',
      ).replace(queryParameters: {'page': '$page'});
      final response = await _get(uri);
      final body = _decode(response);

      if (page == 1 && body['stats'] is Map) {
        final s = (body['stats'] as Map).cast<String, dynamic>();
        final starCounts = <int, int>{};
        if (s['star_counts'] is Map) {
          for (final entry in (s['star_counts'] as Map).entries) {
            starCounts[_intValue(entry.key)] = _intValue(entry.value);
          }
        }
        apiStats = BranchReviewStats(
          averageRating: _doubleValue(s['average_rating']),
          totalReviews: _intValue(s['total_reviews']),
          starCounts: starCounts,
          reviews: [],
        );
      }

      final payload = body['data'];
      final items = payload is Map ? payload['data'] : payload;
      if (items is List) {
        reviews.addAll(
          items.whereType<Map>().map(
            (item) => ReviewItem.fromJson(item.cast<String, dynamic>()),
          ),
        );
      }
      lastPage = payload is Map ? _intValue(payload['last_page']) : page;
      page++;
    } while (page <= lastPage);

    if (apiStats != null) {
      return BranchReviewStats(
        averageRating: apiStats.averageRating,
        totalReviews: apiStats.totalReviews,
        starCounts: apiStats.starCounts,
        reviews: reviews,
      );
    }
    return BranchReviewStats.fromReviews(reviews);
  }

  Future<List<ReviewItem>> fetchBranchReviews(int branchId) async {
    final stats = await fetchBranchReviewStats(branchId);
    return stats.reviews;
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
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decode(response);
      throw AuthException(_message(body));
    }
    return response;
  }

  Future<http.Response> _post(
    Uri uri,
    Map<String, dynamic> body, {
    bool retried = false,
  }) async {
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
    return 'Tidak bisa memproses ulasan.';
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  double _doubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }
}
