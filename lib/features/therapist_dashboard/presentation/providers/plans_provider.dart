import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/therapist_dashboard/data/therapist_repository.dart';
import 'package:orthosense/features/therapist_dashboard/domain/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plans_provider.g.dart';

/// Provider for list of treatment plans.
@riverpod
Future<List<TreatmentPlanModel>> plansList(
  Ref ref, {
  PlanStatus? status,
}) async {
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.getPlans(status: status);
}

/// Provider for a single treatment plan.
@riverpod
Future<TreatmentPlanDetails> plan(Ref ref, String planId) async {
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.getPlan(planId);
}

/// Notifier for treatment plan management.
@riverpod
class PlansNotifier extends _$PlansNotifier {
  @override
  FutureOr<void> build() {}

  Future<TreatmentPlanModel> createPlan({
    required String name,
    required String patientId,
    String? protocolId,
    String notes = '',
    required DateTime startDate,
    DateTime? endDate,
    int frequencyPerWeek = 3,
    Map<String, dynamic> customParameters = const {},
  }) async {
    final repo = ref.read(therapistRepositoryProvider);
    final plan = await repo.createPlan(
      name: name,
      patientId: patientId,
      protocolId: protocolId,
      notes: notes,
      startDate: startDate,
      endDate: endDate,
      frequencyPerWeek: frequencyPerWeek,
      customParameters: customParameters,
    );
    ref.invalidate(plansListProvider);
    return plan;
  }

  /// Adjust/update treatment plan (Plan Adjustment feature).
  Future<TreatmentPlanModel> adjustPlan(
    String planId, {
    String? name,
    String? notes,
    DateTime? endDate,
    int? frequencyPerWeek,
    Map<String, dynamic>? customParameters,
  }) async {
    final repo = ref.read(therapistRepositoryProvider);
    final plan = await repo.updatePlan(
      planId,
      name: name,
      notes: notes,
      endDate: endDate,
      frequencyPerWeek: frequencyPerWeek,
      customParameters: customParameters,
    );
    ref.invalidate(plansListProvider);
    ref.invalidate(planProvider(planId));
    return plan;
  }

  Future<void> activatePlan(String planId) async {
    final repo = ref.read(therapistRepositoryProvider);
    await repo.activatePlan(planId);
    ref.invalidate(plansListProvider);
    ref.invalidate(planProvider(planId));
  }

  Future<void> pausePlan(String planId) async {
    final repo = ref.read(therapistRepositoryProvider);
    await repo.pausePlan(planId);
    ref.invalidate(plansListProvider);
    ref.invalidate(planProvider(planId));
  }

  Future<void> completePlan(String planId) async {
    final repo = ref.read(therapistRepositoryProvider);
    await repo.completePlan(planId);
    ref.invalidate(plansListProvider);
    ref.invalidate(planProvider(planId));
  }
}
