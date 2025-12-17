// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MeasurementsTable extends Measurements
    with TableInfo<$MeasurementsTable, MeasurementEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>('sync_status', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: Constant(SyncStatus.pending.name))
          .withConverter<SyncStatus>($MeasurementsTable.$convertersyncStatus);
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
      jsonData = GeneratedColumn<String>('json_data', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Map<String, dynamic>>(
              $MeasurementsTable.$converterjsonData);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncRetryCountMeta =
      const VerificationMeta('syncRetryCount');
  @override
  late final GeneratedColumn<int> syncRetryCount = GeneratedColumn<int>(
      'sync_retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        type,
        syncStatus,
        jsonData,
        createdAt,
        updatedAt,
        syncRetryCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements';
  @override
  VerificationContext validateIntegrity(Insertable<MeasurementEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('sync_retry_count')) {
      context.handle(
          _syncRetryCountMeta,
          syncRetryCount.isAcceptableOrUnknown(
              data['sync_retry_count']!, _syncRetryCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeasurementEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeasurementEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      syncStatus: $MeasurementsTable.$convertersyncStatus.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}sync_status'])!),
      jsonData: $MeasurementsTable.$converterjsonData.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json_data'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      syncRetryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_retry_count'])!,
    );
  }

  @override
  $MeasurementsTable createAlias(String alias) {
    return $MeasurementsTable(attachedDatabase, alias);
  }

  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
  static TypeConverter<Map<String, dynamic>, String> $converterjsonData =
      const JsonMapConverter();
}

class MeasurementEntry extends DataClass
    implements Insertable<MeasurementEntry> {
  /// Primary key - UUID generated client-side.
  final String id;

  /// Hashed user identifier (SHA-256 + salt per AGENTS.md).
  final String userId;

  /// Measurement type (e.g., 'pose_analysis', 'rom_measurement').
  final String type;

  /// Outbox Pattern: tracks sync state with backend.
  final SyncStatus syncStatus;

  /// Flexible JSON payload for measurement data.
  final Map<String, dynamic> jsonData;

  /// Client-side creation timestamp.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime? updatedAt;

  /// Retry count for failed sync attempts.
  final int syncRetryCount;
  const MeasurementEntry(
      {required this.id,
      required this.userId,
      required this.type,
      required this.syncStatus,
      required this.jsonData,
      required this.createdAt,
      this.updatedAt,
      required this.syncRetryCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    {
      map['sync_status'] = Variable<String>(
          $MeasurementsTable.$convertersyncStatus.toSql(syncStatus));
    }
    {
      map['json_data'] = Variable<String>(
          $MeasurementsTable.$converterjsonData.toSql(jsonData));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['sync_retry_count'] = Variable<int>(syncRetryCount);
    return map;
  }

  MeasurementsCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsCompanion(
      id: Value(id),
      userId: Value(userId),
      type: Value(type),
      syncStatus: Value(syncStatus),
      jsonData: Value(jsonData),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      syncRetryCount: Value(syncRetryCount),
    );
  }

  factory MeasurementEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeasurementEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      syncStatus: serializer.fromJson<SyncStatus>(json['syncStatus']),
      jsonData: serializer.fromJson<Map<String, dynamic>>(json['jsonData']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      syncRetryCount: serializer.fromJson<int>(json['syncRetryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'syncStatus': serializer.toJson<SyncStatus>(syncStatus),
      'jsonData': serializer.toJson<Map<String, dynamic>>(jsonData),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'syncRetryCount': serializer.toJson<int>(syncRetryCount),
    };
  }

  MeasurementEntry copyWith(
          {String? id,
          String? userId,
          String? type,
          SyncStatus? syncStatus,
          Map<String, dynamic>? jsonData,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent(),
          int? syncRetryCount}) =>
      MeasurementEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        syncStatus: syncStatus ?? this.syncStatus,
        jsonData: jsonData ?? this.jsonData,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        syncRetryCount: syncRetryCount ?? this.syncRetryCount,
      );
  MeasurementEntry copyWithCompanion(MeasurementsCompanion data) {
    return MeasurementEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncRetryCount: data.syncRetryCount.present
          ? data.syncRetryCount.value
          : this.syncRetryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('jsonData: $jsonData, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncRetryCount: $syncRetryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, type, syncStatus, jsonData,
      createdAt, updatedAt, syncRetryCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeasurementEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.syncStatus == this.syncStatus &&
          other.jsonData == this.jsonData &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncRetryCount == this.syncRetryCount);
}

class MeasurementsCompanion extends UpdateCompanion<MeasurementEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> type;
  final Value<SyncStatus> syncStatus;
  final Value<Map<String, dynamic>> jsonData;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> syncRetryCount;
  final Value<int> rowid;
  const MeasurementsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncRetryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeasurementsCompanion.insert({
    required String id,
    required String userId,
    required String type,
    this.syncStatus = const Value.absent(),
    required Map<String, dynamic> jsonData,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncRetryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        type = Value(type),
        jsonData = Value(jsonData);
  static Insertable<MeasurementEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? syncStatus,
    Expression<String>? jsonData,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? syncRetryCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (jsonData != null) 'json_data': jsonData,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncRetryCount != null) 'sync_retry_count': syncRetryCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeasurementsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? type,
      Value<SyncStatus>? syncStatus,
      Value<Map<String, dynamic>>? jsonData,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? syncRetryCount,
      Value<int>? rowid}) {
    return MeasurementsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      syncStatus: syncStatus ?? this.syncStatus,
      jsonData: jsonData ?? this.jsonData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncRetryCount: syncRetryCount ?? this.syncRetryCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
          $MeasurementsTable.$convertersyncStatus.toSql(syncStatus.value));
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(
          $MeasurementsTable.$converterjsonData.toSql(jsonData.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncRetryCount.present) {
      map['sync_retry_count'] = Variable<int>(syncRetryCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('jsonData: $jsonData, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncRetryCount: $syncRetryCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MeasurementsTable measurements = $MeasurementsTable(this);
  late final MeasurementsDao measurementsDao =
      MeasurementsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [measurements];
}

typedef $$MeasurementsTableCreateCompanionBuilder = MeasurementsCompanion
    Function({
  required String id,
  required String userId,
  required String type,
  Value<SyncStatus> syncStatus,
  required Map<String, dynamic> jsonData,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> syncRetryCount,
  Value<int> rowid,
});
typedef $$MeasurementsTableUpdateCompanionBuilder = MeasurementsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> type,
  Value<SyncStatus> syncStatus,
  Value<Map<String, dynamic>> jsonData,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> syncRetryCount,
  Value<int> rowid,
});

class $$MeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
      get syncStatus => $composableBuilder(
          column: $table.syncStatus,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<Map<String, dynamic>, Map<String, dynamic>,
          String>
      get jsonData => $composableBuilder(
          column: $table.jsonData,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncRetryCount => $composableBuilder(
      column: $table.syncRetryCount,
      builder: (column) => ColumnFilters(column));
}

class $$MeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jsonData => $composableBuilder(
      column: $table.jsonData, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncRetryCount => $composableBuilder(
      column: $table.syncRetryCount,
      builder: (column) => ColumnOrderings(column));
}

class $$MeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
          column: $table.syncStatus, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncRetryCount => $composableBuilder(
      column: $table.syncRetryCount, builder: (column) => column);
}

class $$MeasurementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MeasurementsTable,
    MeasurementEntry,
    $$MeasurementsTableFilterComposer,
    $$MeasurementsTableOrderingComposer,
    $$MeasurementsTableAnnotationComposer,
    $$MeasurementsTableCreateCompanionBuilder,
    $$MeasurementsTableUpdateCompanionBuilder,
    (
      MeasurementEntry,
      BaseReferences<_$AppDatabase, $MeasurementsTable, MeasurementEntry>
    ),
    MeasurementEntry,
    PrefetchHooks Function()> {
  $$MeasurementsTableTableManager(_$AppDatabase db, $MeasurementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<SyncStatus> syncStatus = const Value.absent(),
            Value<Map<String, dynamic>> jsonData = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> syncRetryCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeasurementsCompanion(
            id: id,
            userId: userId,
            type: type,
            syncStatus: syncStatus,
            jsonData: jsonData,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncRetryCount: syncRetryCount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String type,
            Value<SyncStatus> syncStatus = const Value.absent(),
            required Map<String, dynamic> jsonData,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> syncRetryCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeasurementsCompanion.insert(
            id: id,
            userId: userId,
            type: type,
            syncStatus: syncStatus,
            jsonData: jsonData,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncRetryCount: syncRetryCount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MeasurementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MeasurementsTable,
    MeasurementEntry,
    $$MeasurementsTableFilterComposer,
    $$MeasurementsTableOrderingComposer,
    $$MeasurementsTableAnnotationComposer,
    $$MeasurementsTableCreateCompanionBuilder,
    $$MeasurementsTableUpdateCompanionBuilder,
    (
      MeasurementEntry,
      BaseReferences<_$AppDatabase, $MeasurementsTable, MeasurementEntry>
    ),
    MeasurementEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MeasurementsTableTableManager get measurements =>
      $$MeasurementsTableTableManager(_db, _db.measurements);
}
