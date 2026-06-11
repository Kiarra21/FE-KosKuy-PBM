import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/auth_session.dart';
import '../models/branch_item.dart';
import '../models/branch_photo_item.dart';
import '../models/facility_item.dart';
import 'auth_service.dart';

class BranchService {
  const BranchService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  Future<List<BranchItem>> fetchBranches({int page = 1}) async {
    final branches = <BranchItem>[];
    var currentPage = page;
    var lastPage = page;
    do {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/branches',
      ).replace(queryParameters: {'page': '$currentPage'});
      final response = await _get(uri);
      final body = _decode(response);
      final payload = body['data'];
      final items = payload is Map ? payload['data'] : payload;
      if (items is List) {
        branches.addAll(
          items.whereType<Map>().map(
            (item) => BranchItem.fromJson(item.cast<String, dynamic>()),
          ),
        );
      }
      lastPage = payload is Map ? _intValue(payload['last_page']) : currentPage;
      currentPage++;
    } while (currentPage <= lastPage);
    return branches;
  }

  Future<BranchItem> fetchBranch(int id) async {
    final response = await _get(Uri.parse('${ApiConfig.baseUrl}/branches/$id'));
    final body = _decode(response);
    final payload = body['data'];
    final branch = BranchItem.fromJson(
      (payload is Map ? payload : body).cast<String, dynamic>(),
    );
    final photos = await fetchBranchPhotos(id);
    final counts = await fetchBranchCounts(id);
    return branch.copyWith(
      photos: photos.isEmpty ? branch.photos : photos,
      totalRooms: counts.totalRooms,
      totalGuests: counts.totalGuests,
    );
  }

  Future<BranchItem> createBranch({
    required String name,
    required String description,
    required String address,
    required String longitude,
    required String latitude,
    required String phone,
    required List<int> qrisBytes,
    required String qrisFilename,
    bool isActive = true,
    bool retried = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/branches'),
    );
    request.headers.addAll(_headers());
    request.fields.addAll({
      'name': name,
      'description': description,
      'address': address,
      'longitude': longitude,
      'latitude': latitude,
      'phone': phone,
      'is_active': isActive ? '1' : '0',
    });
    request.files.add(
      http.MultipartFile.fromBytes(
        'qris_code',
        qrisBytes,
        filename: qrisFilename,
      ),
    );
    final streamedResponse = await client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 401 && !retried) {
      try {
        await const AuthService().refresh();
        return createBranch(
          name: name,
          description: description,
          address: address,
          longitude: longitude,
          latitude: latitude,
          phone: phone,
          qrisBytes: qrisBytes,
          qrisFilename: qrisFilename,
          isActive: isActive,
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
    final body = _decode(response);
    final payload = body['data'];
    return BranchItem.fromJson(
      (payload is Map ? payload : body).cast<String, dynamic>(),
    );
  }

  Future<BranchItem> updateBranch({
    required int id,
    required String name,
    required String description,
    required String address,
    required String longitude,
    required String latitude,
    required String phone,
    List<int>? qrisBytes,
    String? qrisFilename,
    bool isActive = true,
    bool retried = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/branches/$id'),
    );
    request.headers.addAll(_headers());
    request.fields.addAll({
      '_method': 'PUT',
      'name': name,
      'description': description,
      'address': address,
      'longitude': longitude,
      'latitude': latitude,
      'phone': phone,
      'is_active': isActive ? '1' : '0',
    });
    if (qrisBytes != null && qrisFilename != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'qris_code',
          qrisBytes,
          filename: qrisFilename,
        ),
      );
    }
    final response = await _send(request);
    if (response.statusCode == 401 && !retried) {
      await const AuthService().refresh();
      return updateBranch(
        id: id,
        name: name,
        description: description,
        address: address,
        longitude: longitude,
        latitude: latitude,
        phone: phone,
        qrisBytes: qrisBytes,
        qrisFilename: qrisFilename,
        isActive: isActive,
        retried: true,
      );
    }
    _ensureSuccess(response);
    final body = _decode(response);
    final payload = body['data'];
    return BranchItem.fromJson(
      (payload is Map ? payload : body).cast<String, dynamic>(),
    );
  }

  Future<void> deleteBranch(int id) async {
    final response = await _request(
      () => client.delete(
        Uri.parse('${ApiConfig.baseUrl}/branches/$id'),
        headers: _headers(),
      ),
    );
    _ensureSuccess(response);
  }

  Future<void> uploadBranchPhoto({
    required int branchId,
    required List<int> photoBytes,
    required String filename,
    int? order,
    bool retried = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/branches/$branchId/photos'),
    );
    request.headers.addAll(_headers());
    if (order != null) request.fields['order'] = '$order';
    request.files.add(
      http.MultipartFile.fromBytes('photo', photoBytes, filename: filename),
    );
    final streamedResponse = await client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 401 && !retried) {
      try {
        await const AuthService().refresh();
        return uploadBranchPhoto(
          branchId: branchId,
          photoBytes: photoBytes,
          filename: filename,
          order: order,
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

  Future<List<String>> fetchBranchPhotos(int id) async {
    final items = await fetchBranchPhotoItems(id);
    return items
        .map((item) => item.url)
        .where((url) => url.isNotEmpty)
        .toList();
  }

  Future<List<BranchPhotoItem>> fetchBranchPhotoItems(int id) async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/branches/$id/photos'),
    );
    final body = _decode(response);
    final items = body['data'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => BranchPhotoItem.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<void> deleteBranchPhoto(int id) async {
    final response = await _request(
      () => client.delete(
        Uri.parse('${ApiConfig.baseUrl}/branch-photos/$id'),
        headers: _headers(),
      ),
    );
    _ensureSuccess(response);
  }

  Future<void> updateBranchPhotoOrder(int id, int order) async {
    final response = await _request(
      () => client.put(
        Uri.parse('${ApiConfig.baseUrl}/branch-photos/$id'),
        headers: {..._headers(), 'Content-Type': 'application/json'},
        body: jsonEncode({'order': order}),
      ),
    );
    _ensureSuccess(response);
  }

  Future<List<FacilityItem>> fetchFacilities({int page = 1}) async {
    final facilities = <FacilityItem>[];
    var currentPage = page;
    var lastPage = page;
    do {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/facilities',
      ).replace(queryParameters: {'page': '$currentPage'});
      final response = await _get(uri);
      final body = _decode(response);
      final payload = body['data'];
      final items = payload is Map ? payload['data'] : payload;
      if (items is List) {
        facilities.addAll(
          items.whereType<Map>().map(
            (item) => FacilityItem.fromJson(item.cast<String, dynamic>()),
          ),
        );
      }
      lastPage = payload is Map ? _intValue(payload['last_page']) : currentPage;
      currentPage++;
    } while (currentPage <= lastPage);
    return facilities;
  }

  Future<FacilityItem> createFacility(String name) async {
    final response = await _request(
      () => client.post(
        Uri.parse('${ApiConfig.baseUrl}/facilities'),
        headers: {..._headers(), 'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      ),
    );
    _ensureSuccess(response);
    final body = _decode(response);
    final payload = body['data'];
    return FacilityItem.fromJson(
      (payload is Map ? payload : body).cast<String, dynamic>(),
    );
  }

  Future<FacilityItem> updateFacility(int id, String name) async {
    final response = await _request(
      () => client.put(
        Uri.parse('${ApiConfig.baseUrl}/facilities/$id'),
        headers: {..._headers(), 'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      ),
    );
    _ensureSuccess(response);
    final body = _decode(response);
    final payload = body['data'];
    return FacilityItem.fromJson(
      (payload is Map ? payload : body).cast<String, dynamic>(),
    );
  }

  Future<void> deleteFacility(int id) async {
    final response = await _request(
      () => client.delete(
        Uri.parse('${ApiConfig.baseUrl}/facilities/$id'),
        headers: _headers(),
      ),
    );
    _ensureSuccess(response);
  }

  Future<List<FacilityItem>> fetchBranchFacilities(int branchId) async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/branches/$branchId/facilities'),
    );
    final body = _decode(response);
    final items = body['data'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => FacilityItem.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<void> syncBranchFacilities(int branchId, List<int> facilityIds) async {
    final response = await _request(
      () => client.put(
        Uri.parse('${ApiConfig.baseUrl}/branches/$branchId/facilities'),
        headers: {..._headers(), 'Content-Type': 'application/json'},
        body: jsonEncode({'facility_ids': facilityIds}),
      ),
    );
    _ensureSuccess(response);
  }

  Future<BranchCounts> fetchBranchCounts(int id) async {
    var totalRooms = 0;
    var totalGuests = 0;
    var page = 1;
    var lastPage = 1;
    do {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/rooms',
      ).replace(queryParameters: {'branch_id': '$id', 'page': '$page'});
      final response = await _get(uri);
      final body = _decode(response);
      final payload = body['data'];
      final items = payload is Map ? payload['data'] : payload;
      if (items is List) {
        for (final room in items.whereType<Map>()) {
          totalRooms++;
          if (_boolValue(room['is_filled'])) totalGuests++;
        }
      }
      lastPage = payload is Map ? _intValue(payload['last_page']) : 1;
      page++;
    } while (page <= lastPage);
    return BranchCounts(totalRooms: totalRooms, totalGuests: totalGuests);
  }

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = '$value'.toLowerCase();
    return text == '1' || text == 'true';
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

  Future<http.Response> _request(
    Future<http.Response> Function() action, {
    bool retried = false,
  }) async {
    final response = await action().timeout(const Duration(seconds: 15));
    if (response.statusCode == 401 && !retried) {
      await const AuthService().refresh();
      return _request(action, retried: true);
    }
    return response;
  }

  Future<http.Response> _send(http.MultipartRequest request) async {
    final streamedResponse = await client
        .send(request)
        .timeout(const Duration(seconds: 30));
    return http.Response.fromStream(streamedResponse);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decode(response);
      throw AuthException(_message(body));
    }
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
    return 'Tidak bisa memuat data cabang.';
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}

class BranchCounts {
  const BranchCounts({required this.totalRooms, required this.totalGuests});

  final int totalRooms;
  final int totalGuests;
}
