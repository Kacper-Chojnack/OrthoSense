import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

/// Provides singleton [AppDatabase] instance.
/// Database is NOT autoDispose - lives for app lifecycle.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
