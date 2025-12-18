import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:orthosense/core/services/preferences_service.dart';
import 'package:orthosense/core/providers/shared_preferences_provider.dart';

part 'preferences_provider.g.dart';

@Riverpod(keepAlive: true)
PreferencesService preferencesService(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs);
}
