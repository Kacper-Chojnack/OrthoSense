import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:orthosense/core/database/sync_status.dart';

/// Converts [SyncStatus] enum to/from database TEXT.
class SyncStatusConverter extends TypeConverter<SyncStatus, String> {
  const SyncStatusConverter();

  @override
  SyncStatus fromSql(String fromDb) => SyncStatus.fromString(fromDb);

  @override
  String toSql(SyncStatus value) => value.name;
}

/// Converts JSON Map to/from database TEXT.
class JsonMapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) =>
      json.decode(fromDb) as Map<String, dynamic>;

  @override
  String toSql(Map<String, dynamic> value) => json.encode(value);
}
