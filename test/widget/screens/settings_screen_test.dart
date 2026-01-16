/// Widget tests for SettingsScreen.
///
/// Test coverage:
/// 1. Screen renders correctly with all sections
/// 2. Appearance section (theme toggle)
/// 3. Voice assistant section
/// 4. Account section (profile, logout, GDPR)
/// 5. About section
/// 6. Dialog interactions
/// 7. Theme integration
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/core/providers/preferences_provider.dart';
import 'package:orthosense/core/services/preferences_service.dart';
import 'package:orthosense/features/auth/data/auth_repository.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';
import 'package:orthosense/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:orthosense/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

// ============================================================================
// Test Helpers
// ============================================================================

Widget createTestWidget({
  required MockAuthRepository mockAuthRepository,
  required MockTokenStorage mockTokenStorage,
  required MockSharedPreferences mockSharedPreferences,
}) {
  final preferencesService = PreferencesService(mockSharedPreferences);
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
      tokenStorageProvider.overrideWithValue(mockTokenStorage),
      preferencesServiceProvider.overrideWithValue(preferencesService),
      // Override theme provider to avoid Drift database initialization
      currentThemeModeProvider.overrideWithValue(ThemeMode.system),
    ],
    child: const MaterialApp(
      home: SettingsScreen(),
    ),
  );
}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockTokenStorage mockTokenStorage;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTokenStorage = MockTokenStorage();
    mockSharedPreferences = MockSharedPreferences();

    // Default setup
    when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(false);
    when(() => mockSharedPreferences.getString(any())).thenReturn(null);
    when(
      () => mockSharedPreferences.setBool(any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockSharedPreferences.setString(any(), any()),
    ).thenAnswer((_) async => true);
  });

  group('SettingsScreen - UI Rendering', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders Appearance section header', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('renders Voice Assistant section header', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.text('Voice Assistant'), findsOneWidget);
    });

    testWidgets('renders Account section header', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('renders About section header', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      // About section is below the fold, need to scroll
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('renders app branding at bottom', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      // Scroll to bottom to see branding
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('OrthoSense'), findsWidgets);
      expect(find.text('Digital Telerehabilitation'), findsOneWidget);
    });
  });

  group('SettingsScreen - Appearance Section', () {
    testWidgets('renders theme toggle with all options', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('renders SegmentedButton for theme selection', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    });

    testWidgets('shows theme description text', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      // Default is system mode
      expect(find.text('Follows your device settings'), findsOneWidget);
    });
  });

  group('SettingsScreen - Account Section', () {
    testWidgets('renders Edit Profile option', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('renders Download My Data option (GDPR)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.text('Download My Data'), findsOneWidget);
      expect(find.text('GDPR: Right to Data Portability'), findsOneWidget);
    });

    testWidgets('renders Sign Out option', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      // Sign Out is below the fold, need to scroll
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsOneWidget);
      // Sign Out uses Image.asset with logo, not Icons.logout
    });

    testWidgets('renders Delete Account option (GDPR)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('GDPR: Right to be Forgotten'), findsOneWidget);
    });
  });

  group('SettingsScreen - Sign Out Dialog', () {
    testWidgets('tapping Sign Out shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      // Sign Out is below the fold, need to scroll first
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Are you sure you want to sign out'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel button dismisses sign out dialog', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      // Sign Out is below the fold, need to scroll first
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(
        find.textContaining('Are you sure you want to sign out'),
        findsNothing,
      );
    });
  });

  group('SettingsScreen - Layout', () {
    testWidgets('content is scrollable', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('uses Card widgets for sections', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      // Multiple cards for different sections
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('uses ListTile for options', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      // Multiple ListTiles for various options
      expect(find.byType(ListTile), findsWidgets);
    });
  });

  group('SettingsScreen - Theme Integration', () {
    testWidgets('renders correctly in light theme', (tester) async {
      final preferencesService = PreferencesService(mockSharedPreferences);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            tokenStorageProvider.overrideWithValue(mockTokenStorage),
            preferencesServiceProvider.overrideWithValue(preferencesService),
            currentThemeModeProvider.overrideWithValue(ThemeMode.system),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const SettingsScreen(),
          ),
        ),
      );

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      final preferencesService = PreferencesService(mockSharedPreferences);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            tokenStorageProvider.overrideWithValue(mockTokenStorage),
            preferencesServiceProvider.overrideWithValue(preferencesService),
            currentThemeModeProvider.overrideWithValue(ThemeMode.system),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const SettingsScreen(),
          ),
        ),
      );

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen - Accessibility', () {
    testWidgets('all sections have readable headers', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Voice Assistant'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      // Scroll down to see About section
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('interactive elements have icons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockAuthRepository: mockAuthRepository,
          mockTokenStorage: mockTokenStorage,
          mockSharedPreferences: mockSharedPreferences,
        ),
      );

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
      // Sign Out and Delete Account use Image.asset instead of Icons
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);

      // Scroll down to see About section icons
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
