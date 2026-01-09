import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/features/auth/data/auth_repository.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';
import 'package:orthosense/features/dashboard/presentation/providers/trend_provider.dart';
import 'package:orthosense/features/dashboard/presentation/screens/dashboard_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockTokenStorage mockTokenStorage;

  const testUser = UserModel(
    id: '123',
    email: 'patient@example.com',
    fullName: 'John Doe',
    role: UserRole.patient,
    isActive: true,
    isVerified: true,
  );

  const testStats = DashboardStats(
    totalSessions: 15,
    sessionsThisWeek: 5,
    averageScore: 87.5,
    activeStreakDays: 3,
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTokenStorage = MockTokenStorage();

    when(
      () => mockTokenStorage.getAccessToken(),
    ).thenAnswer((_) async => 'valid_token');
    when(
      () => mockTokenStorage.isTokenExpired('valid_token'),
    ).thenReturn(false);
    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => testUser);
  });

  Widget createTestWidget({
    DashboardStats stats = testStats,
    bool throwError = false,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        tokenStorageProvider.overrideWithValue(mockTokenStorage),
        dashboardStatsProvider.overrideWith((ref) async {
          if (throwError) {
            throw Exception('Network error');
          }
          return stats;
        }),
        recentExerciseResultsProvider.overrideWith((ref) {
          return const Stream.empty();
        }),
        trendDataProvider.overrideWith((ref, metricType) async {
          return TrendChartData(
            period: TrendPeriod.days7,
            metricType: metricType,
            dataPoints: const [],
          );
        }),
      ],
      child: const MaterialApp(
        home: DashboardScreen(),
      ),
    );
  }

  group('DashboardScreen Widget Tests', () {
    testWidgets('renders dashboard layout correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify app bar
      expect(find.text('OrthoSense'), findsOneWidget);

      // Verify navigation buttons
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);

      // Verify FAB
      expect(find.text('Start Session'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('displays welcome header with user name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show personalized greeting
      expect(find.textContaining('John'), findsWidgets);
    });

    testWidgets('displays stats section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify section headers
      expect(find.text('Your Progress'), findsOneWidget);
      expect(find.text('Recent Sessions'), findsOneWidget);
    });

    testWidgets('shows start session bottom sheet on FAB tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap FAB
      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      // Bottom sheet should appear
      expect(find.text('Select Analysis Method'), findsOneWidget);
      expect(find.text('Analyze from Gallery'), findsOneWidget);
    });

    testWidgets('profile button navigates to profile screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap profile icon
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      // Should show profile screen elements
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('exercise catalog button navigates correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap exercise catalog icon
      await tester.tap(find.byIcon(Icons.menu_book));
      await tester.pumpAndSettle();

      // Should show exercise catalog screen
      expect(find.text('Exercise Catalog'), findsOneWidget);
    });

    testWidgets('activity log button navigates correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap activity log icon
      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();

      // Should show activity log screen
      expect(find.text('Activity Log'), findsOneWidget);
    });

    testWidgets('displays stats grid with correct values', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify stats are displayed
      expect(find.text('15'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.textContaining('87'), findsWidgets);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows empty state for no recent sessions', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // With empty results, should show appropriate message
      expect(find.textContaining('No sessions'), findsOneWidget);
    });
  });

  group('DashboardScreen Bottom Sheet', () {
    testWidgets('shows gallery and live analysis options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Open bottom sheet
      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      // Both options should be visible
      expect(find.text('Analyze from Gallery'), findsOneWidget);
      expect(find.byIcon(Icons.video_library), findsOneWidget);
    });

    testWidgets('gallery option navigates to gallery screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Open bottom sheet
      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      // Tap gallery option
      await tester.tap(find.text('Analyze from Gallery'));
      await tester.pumpAndSettle();

      // Should navigate to gallery analysis screen
      expect(find.text('Gallery Analysis'), findsOneWidget);
    });
  });

  group('DashboardScreen State Handling', () {
    testWidgets('handles error state gracefully', (tester) async {
      await tester.pumpWidget(createTestWidget(throwError: true));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show error state
      expect(find.textContaining('error'), findsWidgets);
    });
  });

  group('DashboardScreen Responsiveness', () {
    testWidgets('adapts to small screen', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('OrthoSense'), findsOneWidget);
      expect(find.text('Start Session'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('adapts to large screen', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('OrthoSense'), findsOneWidget);
      expect(find.text('Start Session'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
