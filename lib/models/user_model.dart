import '../enums/app_enums.dart';

/// Immutable representation of a registered user.
class UserModel {
  const UserModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String email;
  final Gender gender;

  /// Stored only for this demo app. A real app would never keep a
  /// plain-text password — it would store a salted hash on a backend.
  final String password;

  /// Convenience getter for displaying the user's full name.
  String get fullName => '$firstName $lastName';

  /// Initials used for the avatar placeholder.
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'gender': gender.name,
        'password': password,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        gender: Gender.values.firstWhere(
          (g) => g.name == json['gender'],
          orElse: () => Gender.preferNotToSay,
        ),
        password: json['password'] as String,
      );
}
