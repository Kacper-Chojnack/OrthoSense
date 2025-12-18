import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:orthosense/core/database/tables/exercise_results_table.dart';
import 'package:orthosense/core/database/tables/sessions_table.dart';
import 'package:orthosense/core/database/tables/settings_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

export 'package:orthosense/core/database/converters.dart';

part 'app_database.g.dart';

/// Central Drift database - Single Source of Truth for OrthoSense.
/// Offline-First: UI observes Streams from Drift, never reads directly from API.
@DriftDatabase(
  tables: [Settings, Sessions, ExerciseResults],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with custom executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Migration from v1 to v2: add sessions and exercise results tables
        if (from < 2) {
          await m.createTable(sessions);
          await m.createTable(exerciseResults);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'orthosense.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
