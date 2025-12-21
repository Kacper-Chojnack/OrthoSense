import 'package:drift/drift.dart';
import 'package:orthosense/core/database/tables/sessions_table.dart';

/// Local storage for specific exercise results within a session.
/// Links to parent session via foreign key with cascade delete.
class ExerciseResults extends Table {
  /// Unique result identifier (UUID).
  TextColumn get id => text()();

  /// Parent session reference.
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// Exercise type identifier.
  TextColumn get exerciseId => text()();

  /// Human-readable exercise name.
  TextColumn get exerciseName => text()();

  /// Number of sets completed.
  IntColumn get setsCompleted => integer().withDefault(const Constant(0))();

  /// Number of reps completed.
  IntColumn get repsCompleted => integer().withDefault(const Constant(0))();

  /// Exercise score (0-100).
  IntColumn get score => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
