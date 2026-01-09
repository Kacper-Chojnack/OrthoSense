import 'package:orthosense/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

/// Singleton instance of AppDatabase.
AppDatabase? _appDatabaseInstance;

/// Provides singleton [AppDatabase] instance.
/// Database is NOT autoDispose - lives for app lifecycle.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  if (_appDatabaseInstance != null) {
    return _appDatabaseInstance!;
  }
  final db = AppDatabase();
  _appDatabaseInstance = db;
  ref.onDispose(() {
    db.close();
    _appDatabaseInstance = null;
  });
  return db;
}
