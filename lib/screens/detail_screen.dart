import 'package:flutter/material.dart';

import '../models/subject_model.dart';

/// Screen 4 — full details for a single subject selected on the dashboard.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.subject});

  /// The subject passed in from the dashboard.
  final SubjectModel subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Subject Details')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _BannerPlaceholder(title: subject.name),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 6),
                    Text(subject.instructor,
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
                const Divider(height: 32),
                _Section(
                  icon: Icons.description_outlined,
                  title: 'Course Description',
                  child: Text(
                    subject.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 24),
                _Section(
                  icon: Icons.schedule,
                  title: 'Class Timing',
                  child: Text(
                    subject.classTiming,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 24),
                _Section(
                  icon: Icons.event_note,
                  title: 'Schedule Information',
                  child: Text(
                    subject.scheduleInfo,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Coloured banner standing in for a real subject image.
class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder({required this.title});

  final String title;

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
      child: const Center(
        child: Icon(Icons.image, size: 64, color: Colors.white70),
      ),
    );
  }
}

/// A titled content block with a leading icon.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.indigo, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
