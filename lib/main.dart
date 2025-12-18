import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orthosense/core/providers/shared_preferences_provider.dart';
import 'package:orthosense/core/theme/app_theme.dart';
import 'package:orthosense/features/auth/presentation/widgets/auth_wrapper.dart';
import 'package:orthosense/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:orthosense/features/onboarding/presentation/widgets/bootstrap_wrapper.dart';
import 'package:orthosense/features/settings/presentation/providers/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const OrthoSenseApp(),
    ),
  );
}

class OrthoSenseApp extends ConsumerWidget {
  const OrthoSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(currentThemeModeProvider);

    return MaterialApp(
      title: 'OrthoSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const BootstrapWrapper(
        child: AuthWrapper(
          child: DashboardScreen(),
        ),
      ),
    );
  }
}
