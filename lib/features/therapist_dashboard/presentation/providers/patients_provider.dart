import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/therapist_dashboard/data/therapist_repository.dart';
import 'package:orthosense/features/therapist_dashboard/domain/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'patients_provider.g.dart';

/// Provider for list of patients assigned to therapist.
@riverpod
Future<List<PatientModel>> patientsList(Ref ref) async {
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.getPatients();
}

/// Provider for a single patient's data.
@riverpod
Future<PatientModel> patient(Ref ref, String patientId) async {
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.getPatient(patientId);
}

/// Provider for patient's treatment plans.
@riverpod
Future<List<TreatmentPlanDetails>> patientPlans(Ref ref, String patientId) async {
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.getPatientPlans(patientId);
}

/// Provider for patient statistics.
@riverpod
Future<PatientStats> patientStats(Ref ref, String patientId, {String? planId}) async {
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.getPatientStats(patientId, planId: planId);
}

/// Provider for patient's recent sessions (for remote monitoring).
@riverpod
Future<List<SessionSummary>> patientSessions(
  Ref ref,
  String patientId, {
  String? planId,
  int limit = 20,
}) async {
  final repo = ref.watch(therapistRepositoryProvider);
  return repo.getPatientSessions(patientId, planId: planId, limit: limit);
}
