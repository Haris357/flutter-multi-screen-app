import 'package:flutter/material.dart';

import 'course_controller.dart';

/// Exposes a single [CourseController] to the whole widget tree using
/// the same InheritedNotifier pattern as `AuthScope`.
class CourseScope extends InheritedNotifier<CourseController> {
  const CourseScope({
    super.key,
    required CourseController controller,
    required super.child,
  }) : super(notifier: controller);

  static CourseController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CourseScope>();
    assert(scope != null, 'No CourseScope found in the widget tree.');
    return scope!.notifier!;
  }
}
