import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:orthosense/core/database/converters.dart';
import 'package:orthosense/core/database/daos/measurements_dao.dart';
import 'package:orthosense/core/database/sync_status.dart';
import 'package:orthosense/core/database/tables/measurements_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

export 'package:orthosense/core/database/converters.dart';
export 'package:orthosense/core/database/sync_status.dart';

part 'app_database.g.dart';

/// Central Drift database - Single Source of Truth for OrthoSense.
@DriftDatabase(
  tables: [Measurements],
  daos: [MeasurementsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with custom executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Future migrations handled here
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
