import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/auth_session.dart';
import '../models/managed_user.dart';
import 'auth_service.dart';

class OwnerUserService {
  const OwnerUserService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  Future<List<ManagedUser>> fetchUsers({
    String? role,
    String? search,
    bool? isActive,
  }) async {
    final response = await _getList(
      '/users',
      query: {
        if (role != null && role.isNotEmpty) 'role': role,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'is_active': isActive ? '1' : '0',
      },
    );
    return response;
  }

  Future<List<ManagedUser>> fetchCustomers({
    String? search,
    bool? isActive,
  }) async {
    return _getList(
      '/customers',
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'is_active': isActive ? '1' : '0',
      },
    );
  }

  Future<ManagedUser> createUser({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    required String phone,
    required String address,
    required bool isActive,
    int? branchId,
  }) async {
    final response = await _jsonRequest(
      'POST',
      '/users',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
        'phone': phone,
        'address': address,
        'is_active': isActive,
        'branch_id': branchId,
      },
    );
    return _userFromResponse(response);
  }

  Future<ManagedUser> updateUser({
    required int id,
    required String name,
    required String email,
    required String role,
    required String phone,
    required String address,
    required bool isActive,
    String? password,
    int? branchId,
  }) async {
    final response = await _jsonRequest(
      'PUT',
      '/users/$id',
      body: {
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'address': address,
        'is_active': isActive,
        'branch_id': branchId,
        if (password != null && password.isNotEmpty) 'password': password,
        if (password != null && password.isNotEmpty)
          'password_confirmation': password,
      },
    );
    return _userFromResponse(response);
  }

  Future<void> deleteUser(int id) async {
    await _jsonRequest('DELETE', '/users/$id');
  }

  Future<void> updateCustomerStatus(int id, bool isActive) async {
    await _jsonRequest(
      'PUT',
      '/customers/$id/status',
      body: {'is_active': isActive},
    );
  }

  Future<ManagedUser> fetchCustomer(int id) async {
    final response = await _request(
      () => client.get(
        Uri.parse('${ApiConfig.baseUrl}/customers/$id'),
        headers: _headers(),
      ),
    );
    return _userFromResponse(response);
  }

  Future<void> assignAdminToBranch({
    required int branchId,
    required int userId,
  }) async {
    await _jsonRequest('POST', '/branches/$branchId/admins/$userId');
  }

  Future<List<ManagedUser>> fetchBranchAdmins(int branchId) {
    return _getList('/branches/$branchId/admins');
  }

  Future<List<ManagedUser>> fetchAvailableBranchAdmins(int branchId) {
    return _getList('/branches/$branchId/admins/available');
  }

  Future<void> detachAdminFromBranch({
    required int branchId,
    required int userId,
  }) async {
    await _jsonRequest('DELETE', '/branches/$branchId/admins/$userId');
  }

  Future<List<ManagedUser>> _getList(
    String path, {
    Map<String, String>? query,
  }) async {
    final users = <ManagedUser>[];
    var page = 1;
    var lastPage = 1;
    do {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}$path',
      ).replace(queryParameters: {...?query, 'page': '$page'});
      final response = await _request(
        () => client.get(uri, headers: _headers()),
      );
      final body = _decode(response);
      final payload = body['data'];
      final items = payload is Map ? payload['data'] : payload;
      if (items is List) {
        users.addAll(
          items.whereType<Map>().map(
            (item) => ManagedUser.fromJson(item.cast<String, dynamic>()),
          ),
        );
      }
      lastPage = payload is Map ? _intValue(payload['last_page']) : 1;
      page++;
    } while (page <= lastPage);
    return users;
  }

  Future<http.Response> _jsonRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return _request(() {
      final headers = {..._headers(), 'Content-Type': 'application/json'};
      final encodedBody = body == null ? null : jsonEncode(body);
      if (method == 'POST') {
        return client.post(uri, headers: headers, body: encodedBody);
      }
      if (method == 'PUT') {
        return client.put(uri, headers: headers, body: encodedBody);
      }
      return client.delete(uri, headers: headers, body: encodedBody);
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

  ManagedUser _userFromResponse(http.Response response) {
    final body = _decode(response);
    final payload = body['data'];
    return ManagedUser.fromJson(
      (payload is Map ? payload : body).cast<String, dynamic>(),
    );
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
    }
    return 'Terjadi kesalahan. Coba lagi nanti.';
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 1;
  }
}
