import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({AuthService service = const AuthService()})
    : _service = service;

  final AuthService _service;
  bool _loading = false;
  bool _loggingOut = false;
  String? _errorMessage;

  AuthUser? get user => AuthSessionStore.instance.user;
  bool get loading => _loading;
  bool get loggingOut => _loggingOut;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile() async {
    await _run(() => _service.fetchProfile());
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? address,
    List<int>? photoBytes,
    String? photoFilename,
  }) async {
    await _run(() async {
      await _service.updateProfile(
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
      if (photoBytes != null && photoFilename != null) {
        await _service.uploadProfilePhoto(
          bytes: photoBytes,
          filename: photoFilename,
        );
      }
    });
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _run(
      () => _service.updatePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      ),
    );
  }

  Future<void> logout() async {
    _loggingOut = true;
    notifyListeners();
    try {
      await _service.logout();
    } catch (_) {
      await AuthSessionStore.instance.clear();
    } finally {
      _loggingOut = false;
      notifyListeners();
    }
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    _errorMessage = null;
    _loading = true;
    notifyListeners();
    try {
      return await action();
    } on AuthException catch (error) {
      _errorMessage = error.message;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
