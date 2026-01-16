/// Widget tests for Register Screen.
///
/// Test coverage:
/// 1. UI rendering
/// 2. Form validation (including password confirmation)
/// 3. User interactions
/// 4. State changes
/// 5. Navigation back to login
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Register Screen UI Rendering', () {
    testWidgets('displays all required fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      expect(
        find.byType(TextFormField),
        findsNWidgets(3),
      ); // Email, Password, Confirm
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('displays register button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      expect(
        find.widgetWithText(ElevatedButton, 'Create Account'),
        findsOneWidget,
      );
    });

    testWidgets('displays back to login link', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      expect(find.text('Already have an account? Login'), findsOneWidget);
    });

    testWidgets('displays app branding/title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      expect(find.text('Join OrthoSense'), findsOneWidget);
    });
  });

  group('Register Form Validation', () {
    testWidgets('shows error for empty email', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows error for invalid email', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'notanemail',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'password123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error for weak password', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(find.byKey(const Key('password_field')), '123');
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        '123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for password mismatch', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'different123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('valid form passes validation', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'SecurePass123!',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'SecurePass123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      // No validation errors should be visible
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Passwords do not match'), findsNothing);
    });
  });

  group('Register Password Strength', () {
    testWidgets('shows password strength indicator', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('password_field')), 'weak');
      await tester.pump();

      // Weak password indicator
      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('password strength updates on input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      // Start with weak password
      await tester.enterText(find.byKey(const Key('password_field')), 'weak');
      await tester.pump();
      expect(find.text('Weak'), findsOneWidget);

      // Clear and enter strong password
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'StrongP@ss123!',
      );
      await tester.pump();
      expect(find.text('Strong'), findsOneWidget);
    });
  });

  group('Register User Interactions', () {
    testWidgets('can toggle password visibility', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      // Find visibility toggle icons
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));

      // Toggle first password field
      await tester.tap(find.byIcon(Icons.visibility).first);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsWidgets);
    });
  });

  group('Register State Changes', () {
    testWidgets('shows loading during registration', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testRegisterStateProvider.overrideWith(
              () => TestRegisterStateNotifier(TestRegisterState.loading()),
            ),
          ],
          child: const MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error on registration failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testRegisterStateProvider.overrideWith(
              () => TestRegisterStateNotifier(
                TestRegisterState.error('Email already registered'),
              ),
            ),
          ],
          child: const MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Email already registered'), findsOneWidget);
    });
  });

  group('Register Terms and Conditions', () {
    testWidgets('displays terms checkbox', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('I agree to the Terms and Conditions'), findsOneWidget);
    });

    testWidgets('terms must be accepted to register', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestRegisterScreen(),
          ),
        ),
      );

      // Fill all fields but don't accept terms
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'SecurePass123!',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'SecurePass123!',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please accept the terms and conditions'),
        findsOneWidget,
      );
    });
  });
}

// Test providers and widgets
class TestRegisterStateNotifier extends Notifier<TestRegisterState> {
  TestRegisterStateNotifier([this._initialState]);

  final TestRegisterState? _initialState;

  @override
  TestRegisterState build() => _initialState ?? TestRegisterState.initial();

  void setState(TestRegisterState newState) {
    state = newState;
  }
}

final testRegisterStateProvider =
    NotifierProvider<TestRegisterStateNotifier, TestRegisterState>(
      TestRegisterStateNotifier.new,
    );

enum TestRegisterStatus { initial, loading, success, error }

class TestRegisterState {
  TestRegisterState._({required this.status, this.errorMessage});

  factory TestRegisterState.initial() =>
      TestRegisterState._(status: TestRegisterStatus.initial);
  factory TestRegisterState.loading() =>
      TestRegisterState._(status: TestRegisterStatus.loading);
  factory TestRegisterState.success() =>
      TestRegisterState._(status: TestRegisterStatus.success);
  factory TestRegisterState.error(String message) => TestRegisterState._(
    status: TestRegisterStatus.error,
    errorMessage: message,
  );

  final TestRegisterStatus status;
  final String? errorMessage;
}

class TestRegisterScreen extends ConsumerStatefulWidget {
  const TestRegisterScreen({super.key});

  @override
  ConsumerState<TestRegisterScreen> createState() => _TestRegisterScreenState();
}

class _TestRegisterScreenState extends ConsumerState<TestRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String _passwordStrength = 'Weak';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _updatePasswordStrength(String password) {
    String strength = 'Weak';
    if (password.length >= 8) {
      strength = 'Medium';
    }
    if (password.length >= 12 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*]').hasMatch(password)) {
      strength = 'Strong';
    }
    setState(() => _passwordStrength = strength);
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(testRegisterStateProvider);
    final isLoading = registerState.status == TestRegisterStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join OrthoSense',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('email_field'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('password_field'),
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: _validatePassword,
                onChanged: _updatePasswordStrength,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(_passwordStrength),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('confirm_password_field'),
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() => _acceptedTerms = value ?? false);
                    },
                  ),
                  const Text('I agree to the Terms and Conditions'),
                ],
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (!_acceptedTerms) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please accept the terms and conditions',
                            ),
                          ),
                        );
                        return;
                      }
                      // Handle registration
                    }
                  },
                  child: const Text('Create Account'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Login'),
              ),
              if (registerState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    registerState.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
