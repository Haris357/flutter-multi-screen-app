import 'package:flutter/material.dart';

import '../controllers/course_controller.dart';
import '../controllers/course_scope.dart';
import '../models/course_model.dart';
import 'course_detail_screen.dart';
import 'course_form_screen.dart';

/// Lists all courses fetched from the API with create / edit / delete actions.
///
/// Wired to [CourseController] via [CourseScope]; rebuilds automatically as
/// load state and the course list change.
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
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

  Future<void> _refresh() => CourseScope.of(context).loadCourses();

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CourseFormScreen()),
    );
    if (created == true && mounted) {
      _snack('Course added successfully.');
    }
  }

  Future<void> _openEdit(CourseModel course) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CourseFormScreen(existing: course),
      ),
    );
    if (updated == true && mounted) {
      _snack('Course updated.');
    }
  }

  void _openDetail(CourseModel course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(courseId: course.id!),
      ),
    );
  }

  Future<void> _confirmDelete(CourseModel course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text(
          'Are you sure you want to delete "${course.title}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error =
        await CourseScope.of(context).deleteCourse(course.id!);
    if (!mounted) return;
    _snack(error ?? 'Course deleted.');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = CourseScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: controller.state == CourseLoadState.loading
                ? null
                : _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Add course'),
      ),
      body: _buildBody(controller),
    );
  }

  Widget _buildBody(CourseController controller) {
    switch (controller.state) {
      case CourseLoadState.idle:
      case CourseLoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case CourseLoadState.error:
        return _ErrorView(
          message: controller.errorMessage ?? 'Something went wrong.',
          onRetry: _refresh,
        );
      case CourseLoadState.loaded:
        final courses = controller.courses;
        if (courses.isEmpty) {
          return const Center(
            child: Text('No courses yet. Tap "Add course" to create one.'),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: courses.length,
            itemBuilder: (_, i) => _CourseCard(
              course: courses[i],
              onTap: () => _openDetail(courses[i]),
              onEdit: () => _openEdit(courses[i]),
              onDelete: () => _confirmDelete(courses[i]),
            ),
          ),
        );
    }
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final CourseModel course;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      '${course.id ?? '?'}',
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                course.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    onPressed: onEdit,
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
