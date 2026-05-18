import 'package:flutter/material.dart';

import '../controllers/auth_scope.dart';
import '../controllers/navigation_controller.dart';
import '../models/subject_model.dart';
import '../models/user_model.dart';

/// Screen 3 — shows the signed-in user and their enrolled subjects.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.user});

  /// The authenticated user, passed in from the login screen.
  final UserModel user;

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
          _UserHeader(user: user),
          const SizedBox(height: 28),
          Text(
            'Your Subjects',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          // Dynamic list of subjects — tapping one opens its detail page.
          ...kSubjects.map(
            (subject) => _SubjectCard(
              subject: subject,
              onTap: () =>
                  NavigationController.toDetail(context, subject),
            ),
          ),
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

/// Tappable card representing a single subject in the list.
class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.onTap});

  final SubjectModel subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: const Icon(Icons.menu_book, color: Colors.indigo),
        ),
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subject.classTiming),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
