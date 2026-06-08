import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/auth_session.dart';
import '../models/facility_item.dart';
import '../models/managed_room.dart';
import 'auth_service.dart';

class OwnerRoomService {
  const OwnerRoomService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  Future<List<ManagedRoomType>> fetchRoomTypes(int branchId) async {
    final items = await _getList(
      '/room-types',
      query: {'branch_id': '$branchId'},
    );
    return items.map(ManagedRoomType.fromJson).toList();
  }

  Future<ManagedRoomType> createRoomType({
    required int branchId,
    required String name,
    required String description,
    required int price,
    required int roomSize,
    required bool isActive,
    required List<int> facilityIds,
  }) async {
    final response = await _json(
      'POST',
      '/room-types',
      body: {
        'branch_id': branchId,
        'name': name,
        'description': description,
        'price': price,
        'room_size': roomSize,
        'is_active': isActive,
        'facility_ids': facilityIds,
      },
    );
    return ManagedRoomType.fromJson(_data(response));
  }

  Future<ManagedRoomType> updateRoomType({
    required int id,
    required int branchId,
    required String name,
    required String description,
    required int price,
    required int roomSize,
    required bool isActive,
    required List<int> facilityIds,
  }) async {
    final response = await _json(
      'PUT',
      '/room-types/$id',
      body: {
        'branch_id': branchId,
        'name': name,
        'description': description,
        'price': price,
        'room_size': roomSize,
        'is_active': isActive,
        'facility_ids': facilityIds,
      },
    );
    return ManagedRoomType.fromJson(_data(response));
  }

  Future<void> deleteRoomType(int id) async {
    await _json('DELETE', '/room-types/$id');
  }

  Future<List<ManagedRoom>> fetchRooms(int roomTypeId) async {
    final items = await _getList(
      '/rooms',
      query: {'room_type_id': '$roomTypeId'},
    );
    return items.map(ManagedRoom.fromJson).toList();
  }

  Future<List<FacilityItem>> fetchRoomTypeFacilities(int roomTypeId) async {
    final response = await _get('/room-types/$roomTypeId/facilities');
    final body = _decode(response);
    final items = body['data'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => FacilityItem.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<ManagedRoom> createRoom({
    required int roomTypeId,
    required int number,
    required bool isActive,
  }) async {
    final response = await _json(
      'POST',
      '/rooms',
      body: {
        'room_type_id': roomTypeId,
        'number': number,
        'is_active': isActive,
      },
    );
    return ManagedRoom.fromJson(_data(response));
  }

  Future<ManagedRoom> updateRoom({
    required int id,
    required int roomTypeId,
    required int number,
    required bool isActive,
  }) async {
    final response = await _json(
      'PUT',
      '/rooms/$id',
      body: {
        'room_type_id': roomTypeId,
        'number': number,
        'is_active': isActive,
      },
    );
    return ManagedRoom.fromJson(_data(response));
  }

  Future<void> deleteRoom(int id) async {
    await _json('DELETE', '/rooms/$id');
  }

  Future<void> uploadRoomTypePhoto({
    required int roomTypeId,
    required List<int> bytes,
    required String filename,
    bool retried = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/room-types/$roomTypeId/photos'),
    );
    request.headers.addAll(_headers());
    request.files.add(
      http.MultipartFile.fromBytes('photo', bytes, filename: filename),
    );
    final streamed = await client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401 && !retried) {
      await const AuthService().refresh();
      return uploadRoomTypePhoto(
        roomTypeId: roomTypeId,
        bytes: bytes,
        filename: filename,
        retried: true,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decode(response);
      throw AuthException(
        '${body['message'] ?? 'Tidak bisa upload foto kamar.'}',
      );
    }
  }

  Future<List<ManagedRoomPhoto>> fetchRoomTypePhotos(int roomTypeId) async {
    final response = await _get('/room-types/$roomTypeId/photos');
    final body = _decode(response);
    final items = body['data'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => ManagedRoomPhoto.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<void> deleteRoomTypePhoto(int id) async {
    await _json('DELETE', '/room-photos/$id');
  }

  Future<void> updateRoomTypePhotoOrder(int id, int order) async {
    await _json('PUT', '/room-photos/$id', body: {'order': order});
  }

  Future<http.Response> _get(String path, {Map<String, String>? query}) {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: query);
    return _request(() => client.get(uri, headers: _headers()));
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

  Future<http.Response> _json(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return _request(() {
      final headers = {..._headers(), 'Content-Type': 'application/json'};
      final encoded = body == null ? null : jsonEncode(body);
      if (method == 'POST') {
        return client.post(uri, headers: headers, body: encoded);
      }
      if (method == 'PUT') {
        return client.put(uri, headers: headers, body: encoded);
      }
      return client.delete(uri, headers: headers);
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
      throw AuthException('${body['message'] ?? 'Tidak bisa memuat kamar.'}');
    }
    return response;
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 1;
  }

  Map<String, dynamic> _data(http.Response response) {
    final body = _decode(response);
    final payload = body['data'];
    return (payload is Map ? payload : body).cast<String, dynamic>();
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
}
