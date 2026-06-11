import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../services/course_api_service.dart';
import 'course_form_screen.dart';

/// Detail view for a single course.
///
/// Looks up the course in the [CourseController] by id and rebuilds when
/// the underlying list changes (e.g. after an optimistic edit). Falls back
/// to fetching from the API if the course isn't in the cached list.
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final int courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseApiService _api = CourseApiService();

  Future<CourseModel>? _remoteFetch;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CourseController>();
    final cached = controller.courseById(widget.courseId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
        actions: [
          if (cached != null)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CourseFormScreen(existing: cached),
                ),
              ),
            ),
        ],
      ),
      body: cached != null
          ? _CourseDetailBody(course: cached)
          : _buildRemoteFallback(),
    );
  }

  Widget _buildRemoteFallback() {
    _remoteFetch ??= _api.fetchCourse(widget.courseId);
    return FutureBuilder<CourseModel>(
      future: _remoteFetch,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return _CourseDetailBody(course: snapshot.data!);
      },
    );
  }
}

class _CourseDetailBody extends StatelessWidget {
  const _CourseDetailBody({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Banner(id: course.id),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.tag, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Course ID: ${course.id ?? 'unsaved'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: Colors.indigo,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(course.description, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigoAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          id == null ? 'Course' : '#$id',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
