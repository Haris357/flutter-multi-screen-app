import 'package:flutter/material.dart';

import 'auth_controller.dart';

/// Makes a single [AuthController] instance available to the whole
/// widget tree without pulling in an external state-management package.
///
/// Screens access it with `AuthScope.of(context)`.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope found in the widget tree.');
    return scope!.notifier!;
  }
}
