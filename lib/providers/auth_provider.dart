import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService service = const AuthService()})
    : _service = service;

  final AuthService _service;
  bool _loading = false;
  String? _errorMessage;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  AuthSession? get session => AuthSessionStore.instance.session;
  bool get hasValidSession => AuthSessionStore.instance.hasValidSession;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return _run(() => _service.login(email: email, password: password));
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    return _run(
      () => _service.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      ),
    );
  }

  Future<String> forgotPassword({required String email}) {
    return _run(() => _service.forgotPassword(email: email));
  }

  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) {
    return _run(
      () => _service.resetPassword(
        email: email,
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      ),
    );
  }

  Future<void> restoreAndRefresh() async {
    final restored = await AuthSessionStore.instance.restore();
    if (restored == null) {
      notifyListeners();
      return;
    }
    try {
      await _service.refresh();
    } catch (_) {
      await AuthSessionStore.instance.clear();
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _service.logout();
    } catch (_) {
      await AuthSessionStore.instance.clear();
    } finally {
      _setLoading(false);
    }
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      return await action();
    } on AuthException catch (error) {
      _errorMessage = error.message;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
