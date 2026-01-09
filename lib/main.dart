import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/shared_preferences_provider.dart';
import 'package:orthosense/core/services/notification_service.dart';
import 'package:orthosense/core/services/sync/sync_initializer.dart';
import 'package:orthosense/core/theme/app_theme.dart';
import 'package:orthosense/features/auth/presentation/widgets/auth_wrapper.dart';
import 'package:orthosense/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:orthosense/features/onboarding/presentation/widgets/bootstrap_wrapper.dart';
import 'package:orthosense/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:orthosense/widgets/offline_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Global key for accessing ScaffoldMessenger from anywhere
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep the screen on for exercise monitoring and debugging
  await WakelockPlus.enable();

  final prefs = await SharedPreferences.getInstance();

  // Initialize local notifications for session reminders
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const OrthoSenseApp(),
    ),
  );
}

class OrthoSenseApp extends ConsumerStatefulWidget {
  const OrthoSenseApp({super.key});

  @override
  ConsumerState<OrthoSenseApp> createState() => _OrthoSenseAppState();
}

class _OrthoSenseAppState extends ConsumerState<OrthoSenseApp>
    with WidgetsBindingObserver {
  bool _syncInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeSync() async {
    // Delay to ensure providers are ready
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      await SyncInitializer.initialize(ref);
      if (mounted) {
        setState(() => _syncInitialized = true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_syncInitialized) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        SyncInitializer.onAppPaused(ref);
      case AppLifecycleState.resumed:
        SyncInitializer.onAppResumed(ref);
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(currentThemeModeProvider);

    return MaterialApp(
      title: 'OrthoSense',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      highContrastTheme: AppTheme.lightHighContrastTheme,
      highContrastDarkTheme: AppTheme.darkHighContrastTheme,
      themeMode: themeMode,
      home: const BootstrapWrapper(
        child: AuthWrapper(
          child: OfflineBanner(
            child: DashboardScreen(),
          ),
        ),
      ),
    );
  }
}
