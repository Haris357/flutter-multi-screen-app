import 'package:flutter/material.dart';

import '../controllers/auth_scope.dart';
import '../controllers/course_controller.dart';
import '../controllers/course_scope.dart';
import '../controllers/navigation_controller.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import 'course_detail_screen.dart';
import 'course_form_screen.dart';
import 'courses_screen.dart';

/// Screen 3 — shows the signed-in user and a preview of their courses,
/// pulled live from the JSONPlaceholder API.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.user});

  /// The authenticated user, passed in from the login screen.
  final UserModel user;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _initialLoadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadStarted) {
      _initialLoadStarted = true;
      // Defer to after the first frame so listeners are attached first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) CourseScope.of(context).loadCourses();
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await AuthScope.of(context).logout();
    if (context.mounted) {
      NavigationController.toLoginAndClearStack(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _UserHeader(user: widget.user),
          const SizedBox(height: 28),
          const _CoursesPreview(),
        ],
      ),
    );
  }
}

/// User information panel: avatar placeholder, name and email.
class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.indigo.shade100,
          child: Text(
            user.initials,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome,',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                user.fullName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact "Your Courses" panel on the dashboard. Shows the first few items
/// from the API plus quick-access buttons to the full CRUD screen.
class _CoursesPreview extends StatelessWidget {
  const _CoursesPreview();

  static const int _previewCount = 3;

  @override
  Widget build(BuildContext context) {
    final controller = CourseScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Your Courses',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.list_alt),
              label: const Text('View all'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CoursesScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Live data from JSONPlaceholder',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        _buildBody(context, controller),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add course'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CourseFormScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, CourseController controller) {
    switch (controller.state) {
      case CourseLoadState.idle:
      case CourseLoadState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      case CourseLoadState.error:
        return Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.errorMessage ?? 'Failed to load courses.',
                  ),
                ),
                TextButton(
                  onPressed: () => controller.loadCourses(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      case CourseLoadState.loaded:
        final List<CourseModel> all = controller.courses;
        if (all.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No courses yet. Add one to get started.'),
          );
        }
        final preview = all.take(_previewCount).toList();
        return Column(
          children: preview
              .map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: Text(
                        '${c.id ?? '?'}',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      c.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CourseDetailScreen(courseId: c.id!),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
    }
  }
}
