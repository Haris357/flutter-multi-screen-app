import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/course_controller.dart';
import 'controllers/navigation_controller.dart';
import 'enums/app_enums.dart';
import 'repositories/course_repository.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/connectivity_service.dart';
import 'services/course_api_service.dart';
import 'services/course_local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive must be ready before the repository wires up its local cache.
  await Hive.initFlutter();
  final localStorage = await CourseLocalStorage.open();

  final repository = CourseRepository(
    api: CourseApiService(),
    local: localStorage,
    connectivity: ConnectivityService(),
  );

  runApp(
    MultiScreenApp(
      authController: AuthController(),
      courseController: CourseController(repository: repository),
    ),
  );
}

/// Application root. Owns the long-lived [AuthController] and
/// [CourseController] and exposes them through `Provider`.
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<CourseController>.value(value: courseController),
      ],
      child: MaterialApp(
        title: 'Multi-Screen App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const _StartupGate(),
        onGenerateRoute: NavigationController.onGenerateRoute,
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
    _bootstrap ??= context.read<AuthController>().tryAutoLogin();
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

        final auth = context.watch<AuthController>();
        if (auth.state == AuthState.authenticated &&
            auth.currentUser != null) {
          return DashboardScreen(user: auth.currentUser!);
        }
        return const LoginScreen();
      },
    );
  }
}
