import 'package:flutter/material.dart';

import 'controllers/auth_controller.dart';
import 'controllers/auth_scope.dart';
import 'controllers/course_controller.dart';
import 'controllers/course_scope.dart';
import 'controllers/navigation_controller.dart';
import 'enums/app_enums.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiScreenApp(
      authController: AuthController(),
      courseController: CourseController(),
    ),
  );
}

/// Application root. Owns the long-lived [AuthController] and
/// [CourseController] and exposes them to the widget tree through
/// [AuthScope] and [CourseScope].
class MultiScreenApp extends StatelessWidget {
  const MultiScreenApp({
    super.key,
    required this.authController,
    required this.courseController,
  });

  final AuthController authController;
  final CourseController courseController;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: authController,
      child: CourseScope(
        controller: courseController,
        child: MaterialApp(
          title: 'Multi-Screen App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            useMaterial3: true,
          ),
          // The launch screen decides where the user lands.
          home: const _StartupGate(),
          onGenerateRoute: NavigationController.onGenerateRoute,
        ),
      ),
    );
  }
}

/// Shown on launch: attempts to restore a "Remember Me" session and
/// routes the user to the dashboard or the login screen accordingly.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  Future<void>? _bootstrap;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kick off the auto-login attempt exactly once, after the
    // AuthScope dependency is available.
    _bootstrap ??= AuthScope.of(context).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final auth = AuthScope.of(context);
        if (auth.state == AuthState.authenticated &&
            auth.currentUser != null) {
          return DashboardScreen(user: auth.currentUser!);
        }
        return const LoginScreen();
      },
    );
  }
}
