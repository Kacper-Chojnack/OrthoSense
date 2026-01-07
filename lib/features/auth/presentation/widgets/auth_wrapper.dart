import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';
import 'package:orthosense/features/auth/presentation/screens/login_screen.dart';

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
      AuthStateAuthenticated() => child,
      AuthStateUnauthenticated() || AuthStateError() => const LoginScreen(),
    };
  }
}
