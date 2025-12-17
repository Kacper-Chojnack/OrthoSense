import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/database/daos/measurements_dao.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

/// Provides singleton [AppDatabase] instance.
/// Database is NOT autoDispose - lives for app lifecycle.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

/// Provides [MeasurementsDao] for repository layer.
@Riverpod(keepAlive: true)
MeasurementsDao measurementsDao(MeasurementsDaoRef ref) {
  return ref.watch(appDatabaseProvider).measurementsDao;
}
