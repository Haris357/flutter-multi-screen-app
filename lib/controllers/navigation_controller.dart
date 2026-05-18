import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../models/user_model.dart';
import '../screens/dashboard_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/registration_screen.dart';

/// Centralises route names and navigation logic so screens do not have
/// to construct routes or `MaterialPageRoute`s themselves.
class NavigationController {
  NavigationController._();

  static const String registration = '/register';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String detail = '/detail';

  /// Route generator wired into [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case registration:
        return _build(const RegistrationScreen(), settings);
      case login:
        return _build(const LoginScreen(), settings);
      case dashboard:
        final user = settings.arguments as UserModel;
        return _build(DashboardScreen(user: user), settings);
      case detail:
        final subject = settings.arguments as SubjectModel;
        return _build(DetailScreen(subject: subject), settings);
      default:
        return _build(const LoginScreen(), settings);
    }
  }

  static MaterialPageRoute _build(Widget child, RouteSettings settings) =>
      MaterialPageRoute(builder: (_) => child, settings: settings);

  // --- High-level navigation helpers used by the screens -----------------

  /// After a successful registration, go to the login screen.
  static void toLogin(BuildContext context) =>
      Navigator.pushReplacementNamed(context, login);

  /// Open the registration screen from login.
  static void toRegistration(BuildContext context) =>
      Navigator.pushNamed(context, registration);

  /// After a successful login, go to the dashboard with the user data.
  static void toDashboard(BuildContext context, UserModel user) =>
      Navigator.pushReplacementNamed(context, dashboard, arguments: user);

  /// Open a subject's detail screen, passing the selected subject.
  static void toDetail(BuildContext context, SubjectModel subject) =>
      Navigator.pushNamed(context, detail, arguments: subject);

  /// Logout: clear the stack and return to login.
  static void toLoginAndClearStack(BuildContext context) =>
      Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
}
