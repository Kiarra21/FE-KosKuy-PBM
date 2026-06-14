import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: '${json['access_token'] ?? ''}',
      tokenType: '${json['token_type'] ?? 'bearer'}',
      expiresIn: json['expires_in'] is int
          ? json['expires_in'] as int
          : int.tryParse('${json['expires_in']}') ?? 0,
      user: AuthUser.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final AuthUser user;

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }

  AuthSession copyWith({AuthUser? user}) {
    return AuthSession(
      accessToken: accessToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      user: user ?? this.user,
    );
  }
}

class AuthSessionStore {
  AuthSessionStore._();

  static final instance = AuthSessionStore._();

  AuthSession? _session;
  DateTime? _expiresAt;

  static const _sessionKey = 'kos_kuy_auth_session';
  static const _expiresAtKey = 'kos_kuy_auth_expires_at';
  static const _sessionDuration = Duration(days: 7);

  AuthSession? get session => _session;
  AuthUser? get user => _session?.user;
  String? get token => _session?.accessToken;
  bool get hasValidSession {
    final session = _session;
    final expiresAt = _expiresAt;
    if (session == null || session.accessToken.isEmpty || expiresAt == null) {
      return false;
    }
    return DateTime.now().isBefore(expiresAt);
  }

  Future<AuthSession?> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSession = preferences.getString(_sessionKey);
    final rawExpiresAt = preferences.getString(_expiresAtKey);
    final expiresAt = rawExpiresAt == null
        ? null
        : DateTime.tryParse(rawExpiresAt);
    if (rawSession == null ||
        rawSession.isEmpty ||
        expiresAt == null ||
        DateTime.now().isAfter(expiresAt)) {
      await clear();
      return null;
    }
    try {
      final session = AuthSession.fromJson(
        (jsonDecode(rawSession) as Map).cast<String, dynamic>(),
      );
      if (!session.user.isActive) {
        await clear();
        return null;
      }
      _session = session;
      _expiresAt = expiresAt;
      return session;
    } catch (_) {
      await clear();
      return null;
    }
  }

  void save(AuthSession session) {
    _session = session;
    _expiresAt = DateTime.now().add(_sessionDuration);
    unawaited(_persist());
  }

  void saveUser(AuthUser user) {
    final currentSession = _session;
    if (currentSession == null) return;
    _session = currentSession.copyWith(user: user);
    unawaited(_persist());
  }

  Future<void> clear() async {
    _session = null;
    _expiresAt = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
    await preferences.remove(_expiresAtKey);
  }

  Future<void> _persist() async {
    final session = _session;
    final expiresAt = _expiresAt;
    if (session == null || expiresAt == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
    await preferences.setString(_expiresAtKey, expiresAt.toIso8601String());
  }
}
