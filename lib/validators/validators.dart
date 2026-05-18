/// Reusable, UI-independent validation logic.
///
/// Every method returns `null` when the input is valid, or an error
/// message string when it is not — matching the signature expected by
/// Flutter's `TextFormField.validator`.
class Validators {
  Validators._(); // Static-only class; prevent instantiation.

  /// Validates that a required text field is not empty.
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates a name field: required and letters/spaces only.
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    final requiredError = validateRequired(value, fieldName: fieldName);
    if (requiredError != null) return requiredError;

    final name = value!.trim();
    if (name.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(name)) {
      return '$fieldName can only contain letters';
    }
    return null;
  }

  /// Validates that the value is a properly formatted email address.
  static String? validateEmail(String? value) {
    final requiredError = validateRequired(value, fieldName: 'Email');
    if (requiredError != null) return requiredError;

    final email = value!.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a password against the app's security rules:
  /// minimum 6 characters, at least 1 uppercase letter and
  /// at least 1 special character.
  static String? validatePassword(String? value) {
    final requiredError = validateRequired(value, fieldName: 'Password');
    if (requiredError != null) return requiredError;

    final password = value!;
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least 1 uppercase letter';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\/;~`+=]').hasMatch(password)) {
      return 'Password must contain at least 1 special character';
    }
    return null;
  }

  /// Validates that the confirm-password field matches the original.
  static String? validateConfirmPassword(String? value, String original) {
    final requiredError = validateRequired(value, fieldName: 'Confirm password');
    if (requiredError != null) return requiredError;

    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates that a dropdown / selection value has been chosen.
  static String? validateSelection<T>(T? value, {String fieldName = 'Selection'}) {
    if (value == null) {
      return 'Please select a $fieldName';
    }
    return null;
  }
}
