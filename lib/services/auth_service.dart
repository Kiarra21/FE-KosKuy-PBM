import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/auth_session.dart';
import '../models/auth_user.dart';

class AuthService {
  const AuthService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/login'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));
    return _handleAuthResponse(response);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };
    final response = await client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _handleAuthResponse(response);
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 15));
    return _handleMessageResponse(response);
  }

  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'token': token,
            'password': password,
            'password_confirmation': passwordConfirmation,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _handleMessageResponse(response);
  }

  Future<void> logout() async {
    final token = AuthSessionStore.instance.token;
    if (token == null || token.isEmpty) {
      await AuthSessionStore.instance.clear();
      return;
    }
    await client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    await AuthSessionStore.instance.clear();
  }

  Future<AuthUser> fetchProfile() async {
    final response = await client
        .get(Uri.parse('${ApiConfig.baseUrl}/profile'), headers: _authHeaders())
        .timeout(const Duration(seconds: 15));
    final user = _handleUserResponse(response);
    AuthSessionStore.instance.saveUser(user);
    return user;
  }

  Future<AuthSession> refresh() async {
    final response = await client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 15));
    return _handleAuthResponse(response);
  }

  Future<AuthUser> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? address,
  }) async {
    final response = await client
        .put(
          Uri.parse('${ApiConfig.baseUrl}/profile'),
          headers: {..._authHeaders(), 'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'phone': phone,
            'address': address,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final user = _handleUserResponse(response);
    AuthSessionStore.instance.saveUser(user);
    return user;
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await client
        .put(
          Uri.parse('${ApiConfig.baseUrl}/profile/password'),
          headers: {..._authHeaders(), 'Content-Type': 'application/json'},
          body: jsonEncode({
            'current_password': currentPassword,
            'password': password,
            'password_confirmation': passwordConfirmation,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(response.body) as Map).cast<String, dynamic>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_extractMessage(body));
    }
  }

  Future<AuthUser> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/profile/photo'),
    );
    request.headers.addAll(_authHeaders());
    request.files.add(
      http.MultipartFile.fromBytes(
        'profile_picture',
        bytes,
        filename: filename,
      ),
    );
    final streamedResponse = await client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    final user = _handleUserResponse(response);
    AuthSessionStore.instance.saveUser(user);
    return user;
  }

  AuthSession _handleAuthResponse(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(response.body) as Map).cast<String, dynamic>();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final session = AuthSession.fromJson(body);
      if (!session.user.isActive) {
        unawaited(AuthSessionStore.instance.clear());
        throw const AuthException(
          'Akun ini sedang nonaktif dan tidak bisa login.',
        );
      }
      AuthSessionStore.instance.save(session);
      return session;
    }
    throw AuthException(_extractMessage(body));
  }

  AuthUser _handleUserResponse(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(response.body) as Map).cast<String, dynamic>();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final user = AuthUser.fromJson(
        (body['data'] as Map?)?.cast<String, dynamic>() ??
            (body['user'] as Map?)?.cast<String, dynamic>() ??
            body,
      );
      if (!user.isActive) {
        unawaited(AuthSessionStore.instance.clear());
        throw const AuthException('Akun ini sedang nonaktif.');
      }
      return user;
    }
    throw AuthException(_extractMessage(body));
  }

  String _handleMessageResponse(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(response.body) as Map).cast<String, dynamic>();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
      return 'Berhasil.';
    }
    throw AuthException(_extractMessage(body));
  }

  Map<String, String> _authHeaders() {
    final token = AuthSessionStore.instance.token;
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String _extractMessage(Map<String, dynamic> body) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return '${first.first}';
      return '$first';
    }
    return 'Terjadi kesalahan. Coba lagi nanti.';
  }
}

class AuthException implements Exception {
  const AuthException(this.message, {this.canFallback = false});

  final String message;
  final bool canFallback;

  @override
  String toString() => message;
}
