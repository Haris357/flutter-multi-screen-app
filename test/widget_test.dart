// Unit tests for the reusable Validators class.
//
// These exercise the validation logic in isolation, independent of any
// UI, which is exactly why the logic lives in its own class.

import 'package:flutter_test/flutter_test.dart';
import 'package:multi_screen_app/validators/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('accepts a well-formed email', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
    });

    test('rejects an email without a domain', () {
      expect(Validators.validateEmail('user@'), isNotNull);
    });

    test('rejects an empty email', () {
      expect(Validators.validateEmail(''), isNotNull);
    });
  });

  group('Validators.validatePassword', () {
    test('accepts a password meeting every rule', () {
      expect(Validators.validatePassword('Abc#12'), isNull);
    });

    test('rejects a password shorter than 6 characters', () {
      expect(Validators.validatePassword('Ab#1'), isNotNull);
    });

    test('rejects a password with no uppercase letter', () {
      expect(Validators.validatePassword('abc#123'), isNotNull);
    });

    test('rejects a password with no special character', () {
      expect(Validators.validatePassword('Abc123'), isNotNull);
    });
  });

  group('Validators.validateConfirmPassword', () {
    test('accepts matching passwords', () {
      expect(
        Validators.validateConfirmPassword('Abc#12', 'Abc#12'),
        isNull,
      );
    });

    test('rejects mismatched passwords', () {
      expect(
        Validators.validateConfirmPassword('Abc#12', 'Different1!'),
        isNotNull,
      );
    });
  });

  group('Validators.validateRequired', () {
    test('rejects an empty value', () {
      expect(Validators.validateRequired('  '), isNotNull);
    });

    test('accepts a non-empty value', () {
      expect(Validators.validateRequired('hello'), isNull);
    });
  });
}
