import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/therapist_dashboard/data/therapist_repository.dart';
import 'package:orthosense/features/therapist_dashboard/domain/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'protocols_provider.g.dart';

/// Provider for list of protocols.
@riverpod
Future<List<ProtocolModel>> protocolsList(
  Ref ref, {
  bool onlyMine = false,
}) async {
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.getProtocols(onlyMine: onlyMine);
}

/// Provider for a single protocol with exercises.
@riverpod
Future<ProtocolWithExercises> protocol(Ref ref, String protocolId) async {
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.getProtocol(protocolId);
}

/// Notifier for protocol management actions.
@riverpod
class ProtocolsNotifier extends _$ProtocolsNotifier {
  @override
  FutureOr<void> build() {}

  Future<ProtocolModel> createProtocol({
    required String name,
    String description = '',
    String condition = '',
    String phase = '',
    int? durationWeeks,
    int frequencyPerWeek = 3,
  }) async {
    final repo = ref.read(therapistRepositoryProvider);
    final protocol = await repo.createProtocol(
      name: name,
      description: description,
      condition: condition,
      phase: phase,
      durationWeeks: durationWeeks,
      frequencyPerWeek: frequencyPerWeek,
    );
    // Invalidate list to refresh
    ref.invalidate(protocolsListProvider);
    return protocol;
  }

  Future<ProtocolModel> updateProtocol(
    String protocolId, {
    String? name,
    String? description,
    String? condition,
    String? phase,
    int? durationWeeks,
    int? frequencyPerWeek,
    ProtocolStatus? status,
  }) async {
    final repo = ref.read(therapistRepositoryProvider);
    final protocol = await repo.updateProtocol(
      protocolId,
      name: name,
      description: description,
      condition: condition,
      phase: phase,
      durationWeeks: durationWeeks,
      frequencyPerWeek: frequencyPerWeek,
      status: status,
    );
    ref.invalidate(protocolsListProvider);
    ref.invalidate(protocolProvider(protocolId));
    return protocol;
  }

  Future<void> publishProtocol(String protocolId) async {
    await updateProtocol(protocolId, status: ProtocolStatus.published);
  }

  Future<ProtocolExerciseModel> addExerciseToProtocol(
    String protocolId, {
    required String exerciseId,
    int order = 0,
    int sets = 3,
    int? reps,
    int? holdSeconds,
    int restSeconds = 60,
  }) async {
    final repo = ref.read(therapistRepositoryProvider);
    final result = await repo.addExerciseToProtocol(
      protocolId,
      exerciseId: exerciseId,
      order: order,
      sets: sets,
      reps: reps,
      holdSeconds: holdSeconds,
      restSeconds: restSeconds,
    );
    ref.invalidate(protocolProvider(protocolId));
    return result;
  }
}
