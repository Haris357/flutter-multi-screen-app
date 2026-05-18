// Categorical values used across the application.
//
// Keeping these as enums (instead of raw strings) gives us compile-time
// safety and a single source of truth for each category.

/// Gender options shown in the registration dropdown.
enum Gender {
  male('Male'),
  female('Female'),
  other('Other'),
  preferNotToSay('Prefer not to say');

  const Gender(this.label);

  /// Human-readable text shown in the UI.
  final String label;
}

/// Represents where the user currently sits in the auth flow.
enum AuthState {
  /// No user is signed in.
  unauthenticated,

  /// A sign-in / registration request is in progress.
  authenticating,

  /// A user is signed in.
  authenticated,
}

/// Result of an authentication attempt, used to drive UI feedback.
enum AuthStatus {
  success,
  invalidCredentials,
  emailAlreadyExists,
  unknownError,
}
