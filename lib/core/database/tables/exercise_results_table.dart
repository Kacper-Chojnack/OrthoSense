import 'package:drift/drift.dart';
import 'package:orthosense/core/database/tables/sessions_table.dart';

/// Local storage for exercise results (per-exercise within a session).
/// Extended to support full analysis history with feedback details.
class ExerciseResults extends Table {
  /// Unique result identifier (UUID).
  TextColumn get id => text()();

  /// Foreign key to the parent session.
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// Exercise ID from the catalog (for future API sync).
  TextColumn get exerciseId => text()();

  /// Human-readable exercise name.
  TextColumn get exerciseName => text()();

  /// Number of sets completed.
  IntColumn get setsCompleted => integer().withDefault(const Constant(0))();

  /// Number of reps completed.
  IntColumn get repsCompleted => integer().withDefault(const Constant(0))();

  /// Overall score for this exercise (0-100).
  IntColumn get score => integer().nullable()();

  /// Whether the exercise form was correct.
  BoolColumn get isCorrect => boolean().nullable()();

  /// JSON-encoded feedback map (error names -> details).
  TextColumn get feedbackJson => text().nullable()();

  /// Detailed text report from AI analysis.
  TextColumn get textReport => text().nullable()();

  /// Duration of exercise analysis in seconds.
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();

  /// When the exercise was performed.
  DateTimeColumn get performedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Sync status for offline-first pattern.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
