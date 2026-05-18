import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Handles persistence of the registered user and the active session.
///
/// This is a deliberately simple, single-user store backed by
/// [SharedPreferences]. It is enough to demonstrate "Remember Me" and
/// session-survival across app restarts, but is not a real auth backend.
class SessionService {
  static const _registeredUserKey = 'registered_user';
  static const _loggedInEmailKey = 'logged_in_email';
  static const _rememberMeKey = 'remember_me';

  /// Persists a newly registered user.
  Future<void> saveRegisteredUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registeredUserKey, jsonEncode(user.toJson()));
  }

  /// Returns the registered user, or `null` if nobody has registered yet.
  Future<UserModel?> getRegisteredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_registeredUserKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Marks [email] as the active session.
  ///
  /// When [rememberMe] is false the session is treated as transient and
  /// is cleared the next time the app starts.
  Future<void> startSession(String email, {required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInEmailKey, email);
    await prefs.setBool(_rememberMeKey, rememberMe);
  }

  /// Returns the logged-in user if a valid persisted session exists.
  ///
  /// If the last login did not enable "Remember Me", the session is
  /// discarded here so it does not survive an app restart.
  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_loggedInEmailKey);
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (email == null) return null;

    if (!rememberMe) {
      await endSession();
      return null;
    }

    final user = await getRegisteredUser();
    if (user != null && user.email == email) {
      return user;
    }
    return null;
  }

  /// Clears the active session (used on logout).
  Future<void> endSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInEmailKey);
    await prefs.remove(_rememberMeKey);
  }
}
