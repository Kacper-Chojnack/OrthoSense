import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/features/auth/data/auth_repository.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';
import 'package:orthosense/features/auth/presentation/screens/login_screen.dart';
import 'package:orthosense/main.dart' show rootScaffoldMessengerKey;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockTokenStorage mockTokenStorage;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTokenStorage = MockTokenStorage();

    when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => null);
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        tokenStorageProvider.overrideWithValue(mockTokenStorage),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders login form correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify app branding
      expect(find.text('OrthoSense'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);

      // Verify form fields
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Verify buttons
      expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap login button without entering data
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Expect validation errors (actual validation messages from login_screen.dart)
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows email validation error for invalid email', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(
        find.byType(TextFormField).first,
        'invalid-email',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Expect email validation error
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows password visibility toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find visibility toggle icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap to toggle visibility
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('calls login on valid form submission', (tester) async {
      const tokens = AuthTokens(accessToken: 'test_token', tokenType: 'bearer');
      const user = UserModel(id: '1', email: 'test@example.com');

      when(
        () => mockAuthRepository.login(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => tokens);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter valid credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );

      // Submit form
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();

      // Verify login was called
      verify(
        () => mockAuthRepository.login(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    testWidgets('shows error snackbar on login failure', (tester) async {
      when(
        () => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('Invalid credentials'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'wrongpassword1',
      );

      // Submit
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Error snackbar should appear
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('navigates to register screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Sign Up link
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Should navigate to RegisterScreen
      expect(find.text('Join OrthoSense'), findsOneWidget);
    });

    testWidgets('forgot password requires email', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap forgot password without entering email
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Should show snackbar asking for email
      expect(find.text('Please enter your email first'), findsOneWidget);
    });

    testWidgets('forgot password sends email when valid', (tester) async {
      when(
        () => mockAuthRepository.forgotPassword('test@example.com'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter email first
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );

      // Tap forgot password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Verify forgot password was called
      verify(
        () => mockAuthRepository.forgotPassword('test@example.com'),
      ).called(1);

      // Should show success message
      expect(find.text('Password reset email sent'), findsOneWidget);
    });
  });

  group('LoginScreen Accessibility', () {
    testWidgets('has proper input fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Both text fields should be present
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });
}
