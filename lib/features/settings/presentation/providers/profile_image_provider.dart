import 'dart:io';

import 'package:orthosense/features/settings/data/settings_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_image_provider.g.dart';

/// Manages profile image state with persistence.
@Riverpod(keepAlive: true)
class ProfileImageNotifier extends _$ProfileImageNotifier {
  @override
  Future<String?> build() async {
    final repository = ref.watch(settingsRepositoryProvider);
    return repository.loadProfileImagePath();
  }

  /// Save new profile image.
  /// Copies the file to app documents to ensure persistence.
  Future<void> setImage(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imageFile.copy(p.join(appDir.path, fileName));

    final repository = ref.read(settingsRepositoryProvider);

    // Delete old image if exists to save space
    final oldPath = state.value;
    if (oldPath != null) {
      final oldFile = File(oldPath);
      if (oldFile.existsSync()) {
        oldFile.deleteSync();
      }
    }

    await repository.saveProfileImagePath(savedImage.path);
    state = AsyncData(savedImage.path);
  }
}
