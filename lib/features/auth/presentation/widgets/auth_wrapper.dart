import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';
import 'package:orthosense/features/auth/domain/models/user_model.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';
import 'package:orthosense/features/auth/presentation/screens/login_screen.dart';
import 'package:orthosense/features/therapist_dashboard/presentation/screens/therapist_dashboard_screen.dart';

/// Wrapper widget that guards routes based on authentication state.
/// Shows login screen if unauthenticated, child widget if authenticated.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return switch (authState) {
      AuthStateInitial() || AuthStateLoading() => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      ),
      AuthStateAuthenticated(:final user) => _buildAuthenticatedView(user),
      AuthStateUnauthenticated() || AuthStateError() => const LoginScreen(),
    };
  }

  Widget _buildAuthenticatedView(UserModel user) {
    // If user is a therapist or admin, show the therapist dashboard
    // especially if running on web
    if (user.role == UserRole.therapist || user.role == UserRole.admin) {
      if (kIsWeb) {
        return const TherapistDashboardScreen();
      }
      // On mobile, therapists might still want to see the patient view or a mobile dashboard
      // For now, we'll default to the dashboard for them everywhere
      return const TherapistDashboardScreen();
    }

    // Patients see the normal app (child)
    return child;
  }
}
