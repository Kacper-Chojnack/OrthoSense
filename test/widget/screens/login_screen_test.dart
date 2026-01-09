/// Widget tests for LoginScreen.
///
/// Test coverage:
/// 1. Screen renders correctly with all UI elements
/// 2. Form validation (email, password)
/// 3. Login button interactions
/// 4. Loading state during login
/// 5. Error message display
/// 6. Navigation to register screen
/// 7. Forgot password functionality
/// 8. Password visibility toggle
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/features/auth/data/auth_repository.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';
import 'package:orthosense/features/auth/presentation/screens/login_screen.dart';
import 'package:orthosense/features/auth/presentation/screens/register_screen.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

// ============================================================================
// Test Helpers
// ============================================================================

Widget createTestWidget({
  required MockAuthRepository mockAuthRepository,
  required MockTokenStorage mockTokenStorage,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
      tokenStorageProvider.overrideWithValue(mockTokenStorage),
    ],
    child: const MaterialApp(
      home: LoginScreen(),
    ),
  );
}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockTokenStorage mockTokenStorage;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTokenStorage = MockTokenStorage();

    // Default setup - no stored token
    when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => null);
  });

  group('LoginScreen - UI Rendering', () {
    testWidgets('renders app logo/title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      expect(find.text('OrthoSense'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('renders email input field', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('renders password input field', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      expect(find.text('Password'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('renders sign in button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('renders forgot password link', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('renders sign up link', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });
  });

  group('LoginScreen - Form Validation', () {
    testWidgets('shows error when email is empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Enter password only
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );

      // Tap sign in
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Enter invalid email
      await tester.enterText(
        find.byType(TextField).first,
        'invalid-email',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );

      // Tap sign in
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Enter email only
      await tester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );

      // Tap sign in
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows error when password too short', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Enter valid email and short password
      await tester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'short',
      );

      // Tap sign in
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    });
  });

  group('LoginScreen - Password Visibility', () {
    testWidgets('password is obscured by default', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Find password field and check it's obscured
      final passwordField = find.byType(TextField).last;
      final textField = tester.widget<TextField>(passwordField);

      expect(textField.obscureText, isTrue);
    });

    testWidgets('tapping visibility icon toggles password visibility', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Find and tap visibility icon
      final visibilityIcon = find.byIcon(Icons.visibility_outlined);
      expect(visibilityIcon, findsOneWidget);

      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      // Now should show visibility_off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });

  group('LoginScreen - Login Flow', () {
    testWidgets('calls login on valid form submission', (tester) async {
      when(
        () => mockAuthRepository.login(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => const AuthTokens(accessToken: 'token'));
      when(() => mockAuthRepository.getCurrentUser()).thenAnswer(
        (_) async => const UserModel(id: '123', email: 'test@example.com'),
      );

      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Enter credentials
      await tester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );

      // Tap login
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify login was called
      verify(
        () => mockAuthRepository.login(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    testWidgets('sign in button is visible and enabled by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Button should be visible
      expect(find.byType(FilledButton), findsOneWidget);

      // Button is enabled by default (validation happens on submit)
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });
  });

  group('LoginScreen - Navigation', () {
    testWidgets('tapping Sign Up navigates to RegisterScreen', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Tap Sign Up
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Should navigate to RegisterScreen
      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });

  group('LoginScreen - Forgot Password', () {
    testWidgets('forgot password shows snackbar when email empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Tap forgot password without entering email
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email first'), findsOneWidget);
    });

    testWidgets('forgot password calls repository when email provided', (
      tester,
    ) async {
      when(
        () => mockAuthRepository.forgotPassword('test@example.com'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Enter email
      await tester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );

      // Tap forgot password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      verify(
        () => mockAuthRepository.forgotPassword('test@example.com'),
      ).called(1);
    });
  });

  group('LoginScreen - Accessibility', () {
    testWidgets('has semantic labels for screen readers', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
        ),
      );

      // Check for proper semantics
      expect(
        find.bySemanticsLabel(RegExp('Email')),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(RegExp('Password')),
        findsWidgets,
      );
    });
  });
}
