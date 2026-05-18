import 'package:flutter/foundation.dart';

import '../enums/app_enums.dart';
import '../models/user_model.dart';
import '../services/session_service.dart';

/// Outcome of an authentication operation, bundling a status with an
/// optional human-readable message for the UI to display.
class AuthResult {
  const AuthResult(this.status, [this.message]);

  final AuthStatus status;
  final String? message;

  bool get isSuccess => status == AuthStatus.success;
}

/// Controller that owns all authentication business logic.
///
/// The UI layer talks only to this class — it never touches
/// [SessionService] or [SharedPreferences] directly. This keeps the
/// screens free of business logic and makes the flow easy to test.
class AuthController extends ChangeNotifier {
  AuthController({SessionService? sessionService})
      : _session = sessionService ?? SessionService();

  final SessionService _session;

  AuthState _state = AuthState.unauthenticated;
  AuthState get state => _state;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  /// Attempts to silently restore a "Remember Me" session on app launch.
  Future<void> tryAutoLogin() async {
    final user = await _session.restoreSession();
    if (user != null) {
      _currentUser = user;
      _setState(AuthState.authenticated);
    }
  }

  /// Registers a new user. Fails if the email is already registered.
  Future<AuthResult> register(UserModel user) async {
    _setState(AuthState.authenticating);
    await _fakeNetworkDelay();

    final existing = await _session.getRegisteredUser();
    if (existing != null && existing.email == user.email) {
      _setState(AuthState.unauthenticated);
      return const AuthResult(
        AuthStatus.emailAlreadyExists,
        'An account with this email already exists.',
      );
    }

    await _session.saveRegisteredUser(user);
    _setState(AuthState.unauthenticated);
    return const AuthResult(AuthStatus.success, 'Registration successful!');
  }

  /// Validates credentials and, on success, starts a session.
  Future<AuthResult> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    _setState(AuthState.authenticating);
    await _fakeNetworkDelay();

    final user = await _session.getRegisteredUser();
    final matches = user != null &&
        user.email.toLowerCase() == email.trim().toLowerCase() &&
        user.password == password;

    if (!matches) {
      _setState(AuthState.unauthenticated);
      return const AuthResult(
        AuthStatus.invalidCredentials,
        'Incorrect email or password.',
      );
    }

    await _session.startSession(user.email, rememberMe: rememberMe);
    _currentUser = user;
    _setState(AuthState.authenticated);
    return const AuthResult(AuthStatus.success, 'Welcome back!');
  }

  /// Ends the session and returns the app to an unauthenticated state.
  Future<void> logout() async {
    await _session.endSession();
    _currentUser = null;
    _setState(AuthState.unauthenticated);
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Simulates the latency of a real backend call so loading
  /// indicators in the UI are observable.
  Future<void> _fakeNetworkDelay() =>
      Future.delayed(const Duration(milliseconds: 600));
}
