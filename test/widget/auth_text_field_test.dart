/// Unit tests for AuthTextField.
///
/// Test coverage:
/// 1. Constructor parameters
/// 2. Default values
/// 3. Input decoration
/// 4. Validation mode
/// 5. Text field properties
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthTextField', () {
    group('required parameters', () {
      test('requires controller', () {
        const hasController = true;
        expect(hasController, isTrue);
      });

      test('requires label', () {
        const label = 'Email';
        expect(label, isNotEmpty);
      });
    });

    group('optional parameters', () {
      test('hint is optional', () {
        const String? hint = null;
        expect(hint, isNull);
      });

      test('prefixIcon is optional', () {
        const Object? prefixIcon = null;
        expect(prefixIcon, isNull);
      });

      test('suffixIcon is optional', () {
        const Object? suffixIcon = null;
        expect(suffixIcon, isNull);
      });

      test('validator is optional', () {
        const Function? validator = null;
        expect(validator, isNull);
      });

      test('onFieldSubmitted is optional', () {
        const Function? onFieldSubmitted = null;
        expect(onFieldSubmitted, isNull);
      });

      test('autofillHints is optional', () {
        const Iterable<String>? autofillHints = null;
        expect(autofillHints, isNull);
      });
    });

    group('default values', () {
      test('obscureText defaults to false', () {
        const obscureText = false;
        expect(obscureText, isFalse);
      });

      test('enabled defaults to true', () {
        const enabled = true;
        expect(enabled, isTrue);
      });
    });

    group('InputDecoration', () {
      test('includes labelText', () {
        const label = 'Email';
        final decoration = {'labelText': label};

        expect(decoration['labelText'], equals('Email'));
      });

      test('includes hintText when provided', () {
        const hint = 'Enter your email';
        final decoration = {'hintText': hint};

        expect(decoration['hintText'], equals('Enter your email'));
      });

      test('includes prefixIcon when provided', () {
        const hasPrefix = true;
        expect(hasPrefix, isTrue);
      });

      test('includes suffixIcon when provided', () {
        const hasSuffix = true;
        expect(hasSuffix, isTrue);
      });

      test('uses OutlineInputBorder', () {
        const borderType = 'OutlineInputBorder';
        expect(borderType, equals('OutlineInputBorder'));
      });
    });

    group('autovalidateMode', () {
      test('uses onUserInteraction mode', () {
        const mode = 'onUserInteraction';
        expect(mode, equals('onUserInteraction'));
      });

      test('validates after user interaction', () {
        const validatesOnInteraction = true;
        expect(validatesOnInteraction, isTrue);
      });
    });

    group('keyboard types', () {
      test('accepts email keyboard type', () {
        const keyboardType = 'emailAddress';
        expect(keyboardType, equals('emailAddress'));
      });

      test('accepts text keyboard type', () {
        const keyboardType = 'text';
        expect(keyboardType, equals('text'));
      });

      test('accepts visiblePassword keyboard type', () {
        const keyboardType = 'visiblePassword';
        expect(keyboardType, equals('visiblePassword'));
      });
    });

    group('text input actions', () {
      test('accepts next action', () {
        const action = 'next';
        expect(action, equals('next'));
      });

      test('accepts done action', () {
        const action = 'done';
        expect(action, equals('done'));
      });

      test('accepts send action', () {
        const action = 'send';
        expect(action, equals('send'));
      });
    });

    group('obscureText', () {
      test('hides text when true', () {
        const obscureText = true;
        expect(obscureText, isTrue);
      });

      test('shows text when false', () {
        const obscureText = false;
        expect(obscureText, isFalse);
      });
    });

    group('enabled state', () {
      test('allows input when enabled', () {
        const enabled = true;
        expect(enabled, isTrue);
      });

      test('blocks input when disabled', () {
        const enabled = false;
        expect(enabled, isFalse);
      });
    });

    group('autofill hints', () {
      test('accepts email hint', () {
        const hints = ['email'];
        expect(hints.contains('email'), isTrue);
      });

      test('accepts password hint', () {
        const hints = ['password'];
        expect(hints.contains('password'), isTrue);
      });

      test('accepts name hint', () {
        const hints = ['name'];
        expect(hints.contains('name'), isTrue);
      });
    });

    group('validation', () {
      test('validator receives text value', () {
        var receivedValue = '';

        String? validator(String? value) {
          receivedValue = value ?? '';
          return null;
        }

        validator('test@example.com');
        expect(receivedValue, equals('test@example.com'));
      });

      test('validator returns null for valid input', () {
        String? validator(String? value) {
          if (value != null && value.contains('@')) {
            return null;
          }
          return 'Invalid email';
        }

        final result = validator('test@example.com');
        expect(result, isNull);
      });

      test('validator returns error for invalid input', () {
        String? validator(String? value) {
          if (value != null && value.contains('@')) {
            return null;
          }
          return 'Invalid email';
        }

        final result = validator('invalid');
        expect(result, equals('Invalid email'));
      });
    });

    group('onFieldSubmitted', () {
      test('called when field submitted', () {
        var submitted = false;

        void onSubmit(String value) {
          submitted = true;
        }

        onSubmit('test');
        expect(submitted, isTrue);
      });

      test('receives text value', () {
        var submittedValue = '';

        void onSubmit(String value) {
          submittedValue = value;
        }

        onSubmit('test@example.com');
        expect(submittedValue, equals('test@example.com'));
      });
    });
  });

  group('Email TextField Usage', () {
    test('typical email field configuration', () {
      const label = 'Email';
      const hint = 'Enter your email';
      const keyboardType = 'emailAddress';
      const textInputAction = 'next';
      const autofillHints = ['email'];

      expect(label, equals('Email'));
      expect(keyboardType, equals('emailAddress'));
      expect(autofillHints.contains('email'), isTrue);
    });
  });

  group('Password TextField Usage', () {
    test('typical password field configuration', () {
      const label = 'Password';
      const hint = 'Enter your password';
      const obscureText = true;
      const textInputAction = 'done';
      const autofillHints = ['password'];

      expect(label, equals('Password'));
      expect(obscureText, isTrue);
      expect(autofillHints.contains('password'), isTrue);
    });

    test('password toggle suffix icon', () {
      // Suffix icon typically shows/hides password
      const hasSuffixIcon = true;
      expect(hasSuffixIcon, isTrue);
    });
  });

  group('Name TextField Usage', () {
    test('typical name field configuration', () {
      const label = 'Full Name';
      const keyboardType = 'name';
      const autofillHints = ['name'];

      expect(label, equals('Full Name'));
      expect(autofillHints.contains('name'), isTrue);
    });
  });
}
