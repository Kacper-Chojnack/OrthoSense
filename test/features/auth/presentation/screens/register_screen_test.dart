import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/features/auth/data/auth_repository.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';
import 'package:orthosense/features/auth/presentation/screens/register_screen.dart';

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
      child: const MaterialApp(
        home: RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders registration form correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Header text
      expect(find.text('Join OrthoSense'), findsOneWidget);
      expect(
        find.text('Create an account to start your rehabilitation journey'),
        findsOneWidget,
      );

      // Form fields
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Sign In link
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the Create Account button
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();

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
        'not-an-email',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'password123',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows password length validation error', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'short',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'short',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsWidgets);
    });

    testWidgets('shows password mismatch error', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'differentpassword',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows password visibility toggles', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('calls register on valid form submission', (tester) async {
      const user = UserModel(id: '1', email: 'new@example.com');
      const tokens = AuthTokens(accessToken: 'test_token', tokenType: 'bearer');

      when(
        () => mockAuthRepository.register(
          email: 'new@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => user);

      when(
        () => mockAuthRepository.login(
          email: 'new@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => tokens);

      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'new@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'password123',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();

      verify(
        () => mockAuthRepository.register(
          email: 'new@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    testWidgets('shows error snackbar on registration failure', (tester) async {
      when(
        () => mockAuthRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 400,
            data: {'detail': 'Email already registered'},
          ),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'existing@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'password123',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows password hint text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    });
  });

  group('RegisterScreen Accessibility', () {
    testWidgets('has proper input fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // All three text fields should be present
      expect(find.byType(TextFormField), findsNWidgets(3));
    });
  });
}
