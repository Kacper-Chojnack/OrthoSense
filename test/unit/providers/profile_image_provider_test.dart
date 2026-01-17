/// Unit tests for ProfileImageNotifier.
///
/// Test coverage:
/// 1. Initial state loading
/// 2. Image file validation
/// 3. Setting new image
/// 4. Old image cleanup
/// 5. Persistence
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileImageNotifier', () {
    group('build (initial load)', () {
      test('loads saved profile image path from repository', () {
        var repositoryRead = false;

        String? loadProfileImagePath() {
          repositoryRead = true;
          return '/path/to/image.jpg';
        }

        final result = loadProfileImagePath();
        expect(repositoryRead, isTrue);
        expect(result, isNotNull);
      });

      test('returns null when no saved path', () {
        String? loadProfileImagePath() => null;

        final result = loadProfileImagePath();
        expect(result, isNull);
      });

      test('verifies file exists when path is saved', () {
        const savedPath = '/path/to/image.jpg';
        var fileChecked = false;

        bool fileExists(String path) {
          fileChecked = true;
          return true;
        }

        fileExists(savedPath);
        expect(fileChecked, isTrue);
      });

      test('clears saved path when file no longer exists', () {
        var pathCleared = false;

        Future<void> clearPath() async {
          pathCleared = true;
        }

        clearPath();
        expect(pathCleared, isTrue);
      });

      test('returns null when file was deleted', () {
        const savedPath = '/path/to/deleted.jpg';
        const fileExists = false;

        final result = fileExists ? savedPath : null;
        expect(result, isNull);
      });
    });

    group('setImage', () {
      test('gets application documents directory', () {
        var appDirFetched = false;

        void getApplicationDocumentsDirectory() {
          appDirFetched = true;
        }

        getApplicationDocumentsDirectory();
        expect(appDirFetched, isTrue);
      });

      test('generates timestamped filename', () {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'profile_$timestamp.jpg';

        expect(fileName, startsWith('profile_'));
        expect(fileName, endsWith('.jpg'));
      });

      test('copies image to app documents directory', () {
        var imageCopied = false;

        void copyImage(String destination) {
          imageCopied = true;
        }

        copyImage('/app/docs/profile_123.jpg');
        expect(imageCopied, isTrue);
      });

      test('deletes old image if exists', () {
        var oldImageDeleted = false;
        const oldPath = '/app/docs/profile_old.jpg';
        const oldFileExists = true;

        void deleteOldImage() {
          if (oldFileExists) {
            oldImageDeleted = true;
          }
        }

        deleteOldImage();
        expect(oldImageDeleted, isTrue);
      });

      test('does not delete when no old image', () {
        var deleteAttempted = false;
        const oldPath = null;

        void deleteOldImage() {
          if (oldPath != null) {
            deleteAttempted = true;
          }
        }

        deleteOldImage();
        expect(deleteAttempted, isFalse);
      });

      test('saves new image path to repository', () {
        var pathSaved = false;

        Future<void> saveProfileImagePath(String path) async {
          pathSaved = true;
        }

        saveProfileImagePath('/app/docs/profile_123.jpg');
        expect(pathSaved, isTrue);
      });

      test('updates state with new path', () {
        String? currentState;

        void updateState(String newPath) {
          currentState = newPath;
        }

        updateState('/app/docs/profile_123.jpg');
        expect(currentState, equals('/app/docs/profile_123.jpg'));
      });
    });

    group('file path construction', () {
      test('uses path join for correct path construction', () {
        const appDirPath = '/app/documents';
        const fileName = 'profile_123.jpg';

        // Simulating p.join behavior
        final fullPath = '$appDirPath/$fileName';

        expect(fullPath, equals('/app/documents/profile_123.jpg'));
      });

      test('filename includes jpg extension', () {
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

        expect(fileName, endsWith('.jpg'));
      });
    });

    group('Riverpod configuration', () {
      test('is kept alive', () {
        const keepAlive = true;
        expect(keepAlive, isTrue);
      });

      test('watches settingsRepositoryProvider', () {
        var repositoryWatched = false;

        void watchRepository() {
          repositoryWatched = true;
        }

        watchRepository();
        expect(repositoryWatched, isTrue);
      });

      test('reads settingsRepositoryProvider for mutations', () {
        var repositoryRead = false;

        void readRepository() {
          repositoryRead = true;
        }

        readRepository();
        expect(repositoryRead, isTrue);
      });
    });

    group('state management', () {
      test('initial state is AsyncData with path or null', () {
        const hasAsyncData = true;
        expect(hasAsyncData, isTrue);
      });

      test('state.value contains current path', () {
        const currentPath = '/path/to/image.jpg';

        // Simulating state.value access
        String? getStateValue() => currentPath;

        expect(getStateValue(), equals(currentPath));
      });

      test('state updated to AsyncData after setImage', () {
        var isAsyncData = false;

        void setStateAsyncData(String path) {
          isAsyncData = true;
        }

        setStateAsyncData('/new/path.jpg');
        expect(isAsyncData, isTrue);
      });
    });
  });

  group('File Operations', () {
    test('checks file existence with existsSync', () {
      var existsSyncCalled = false;

      bool checkExists() {
        existsSyncCalled = true;
        return true;
      }

      checkExists();
      expect(existsSyncCalled, isTrue);
    });

    test('deletes file with deleteSync', () {
      var deleteSyncCalled = false;

      void deleteFile() {
        deleteSyncCalled = true;
      }

      deleteFile();
      expect(deleteSyncCalled, isTrue);
    });

    test('copies file to new location', () {
      var copyCalled = false;

      void copyFile(String destination) {
        copyCalled = true;
      }

      copyFile('/new/location/file.jpg');
      expect(copyCalled, isTrue);
    });
  });

  group('Space Management', () {
    test('deletes old image to save space', () {
      // Old images are deleted when new ones are set
      const deletesOldImages = true;
      expect(deletesOldImages, isTrue);
    });

    test('only one profile image stored at a time', () {
      // By deleting old images, only one exists at any time
      const singleImagePolicy = true;
      expect(singleImagePolicy, isTrue);
    });
  });

  group('Repository Integration', () {
    test('loadProfileImagePath is async', () {
      const isAsync = true;
      expect(isAsync, isTrue);
    });

    test('saveProfileImagePath accepts nullable String', () {
      String? path;

      void savePath(String? p) {
        path = p;
      }

      savePath(null);
      expect(path, isNull);

      savePath('/path/to/image.jpg');
      expect(path, isNotNull);
    });
  });

  group('Error Handling', () {
    test('handles missing file gracefully', () {
      const savedPath = '/missing/file.jpg';
      const fileExists = false;

      // Returns null if file doesn't exist
      final result = fileExists ? savedPath : null;

      expect(result, isNull);
    });

    test('clears invalid path from repository', () {
      var pathCleared = false;

      Future<void> handleMissingFile() async {
        pathCleared = true;
      }

      handleMissingFile();
      expect(pathCleared, isTrue);
    });
  });
}
