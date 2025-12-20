import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/therapist_dashboard/domain/models/models.dart';
import 'package:orthosense/infrastructure/networking/dio_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'therapist_repository.g.dart';

/// Repository for therapist dashboard API operations.
class TherapistRepository {
  TherapistRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // --- Patients ---

  /// Get list of patients assigned to current therapist.
  Future<List<PatientModel>> getPatients({bool activeOnly = true}) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/patients',
      queryParameters: {'active_only': activeOnly},
    );
    return response.data!
        .map((json) => PatientModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific patient.
  Future<PatientModel> getPatient(String patientId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/patients/$patientId',
    );
    return PatientModel.fromJson(response.data!);
  }

  /// Get patient's treatment plans.
  Future<List<TreatmentPlanDetails>> getPatientPlans(
    String patientId, {
    PlanStatus? status,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/patients/$patientId/plans',
      queryParameters: status != null ? {'status_filter': status.name} : null,
    );
    return response.data!
        .map(
          (json) => TreatmentPlanDetails.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get patient statistics for monitoring.
  Future<PatientStats> getPatientStats(
    String patientId, {
    String? planId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/patients/$patientId/stats',
      queryParameters: planId != null ? {'plan_id': planId} : null,
    );
    return PatientStats.fromJson(response.data!);
  }

  /// Get patient's recent sessions.
  Future<List<SessionSummary>> getPatientSessions(
    String patientId, {
    String? planId,
    SessionStatus? status,
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/patients/$patientId/sessions',
      queryParameters: {
        if (planId != null) 'plan_id': planId,
        if (status != null) 'status_filter': status.name,
        'skip': skip,
        'limit': limit,
      },
    );
    return response.data!
        .map((json) => SessionSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // --- Protocols ---

  /// Get list of protocols.
  Future<List<ProtocolModel>> getProtocols({
    ProtocolStatus? status,
    String? condition,
    bool onlyMine = false,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/protocols',
      queryParameters: {
        if (status != null) 'status_filter': status.name,
        if (condition != null) 'condition': condition,
        'only_mine': onlyMine,
      },
    );
    return response.data!
        .map((json) => ProtocolModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get protocol with exercises.
  Future<ProtocolWithExercises> getProtocol(String protocolId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/protocols/$protocolId',
    );
    return ProtocolWithExercises.fromJson(response.data!);
  }

  /// Create a new protocol.
  Future<ProtocolModel> createProtocol({
    required String name,
    String description = '',
    String condition = '',
    String phase = '',
    int? durationWeeks,
    int frequencyPerWeek = 3,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/protocols',
      data: {
        'name': name,
        'description': description,
        'condition': condition,
        'phase': phase,
        if (durationWeeks != null) 'duration_weeks': durationWeeks,
        'frequency_per_week': frequencyPerWeek,
      },
    );
    return ProtocolModel.fromJson(response.data!);
  }

  /// Update protocol.
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
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/protocols/$protocolId',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (condition != null) 'condition': condition,
        if (phase != null) 'phase': phase,
        if (durationWeeks != null) 'duration_weeks': durationWeeks,
        if (frequencyPerWeek != null) 'frequency_per_week': frequencyPerWeek,
        if (status != null) 'status': status.name,
      },
    );
    return ProtocolModel.fromJson(response.data!);
  }

  /// Add exercise to protocol.
  Future<ProtocolExerciseModel> addExerciseToProtocol(
    String protocolId, {
    required String exerciseId,
    int order = 0,
    int sets = 3,
    int? reps,
    int? holdSeconds,
    int restSeconds = 60,
    String notes = '',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/protocols/$protocolId/exercises',
      data: {
        'exercise_id': exerciseId,
        'order': order,
        'sets': sets,
        if (reps != null) 'reps': reps,
        if (holdSeconds != null) 'hold_seconds': holdSeconds,
        'rest_seconds': restSeconds,
        'notes': notes,
      },
    );
    return ProtocolExerciseModel.fromJson(response.data!);
  }

  // --- Treatment Plans ---

  /// Get treatment plans.
  Future<List<TreatmentPlanModel>> getPlans({PlanStatus? status}) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/plans',
      queryParameters: status != null ? {'status_filter': status.name} : null,
    );
    return response.data!
        .map(
          (json) => TreatmentPlanModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get treatment plan details.
  Future<TreatmentPlanDetails> getPlan(String planId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/plans/$planId',
    );
    return TreatmentPlanDetails.fromJson(response.data!);
  }

  /// Create treatment plan for a patient.
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
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/plans',
      data: {
        'name': name,
        'patient_id': patientId,
        if (protocolId != null) 'protocol_id': protocolId,
        'notes': notes,
        'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null)
          'end_date': endDate.toIso8601String().split('T')[0],
        'frequency_per_week': frequencyPerWeek,
        'custom_parameters': customParameters,
      },
    );
    return TreatmentPlanModel.fromJson(response.data!);
  }

  /// Update/adjust treatment plan.
  Future<TreatmentPlanModel> updatePlan(
    String planId, {
    String? name,
    String? notes,
    DateTime? endDate,
    PlanStatus? status,
    int? frequencyPerWeek,
    Map<String, dynamic>? customParameters,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/plans/$planId',
      data: {
        if (name != null) 'name': name,
        if (notes != null) 'notes': notes,
        if (endDate != null)
          'end_date': endDate.toIso8601String().split('T')[0],
        if (status != null) 'status': status.name,
        if (frequencyPerWeek != null) 'frequency_per_week': frequencyPerWeek,
        if (customParameters != null) 'custom_parameters': customParameters,
      },
    );
    return TreatmentPlanModel.fromJson(response.data!);
  }

  /// Activate a treatment plan.
  Future<TreatmentPlanModel> activatePlan(String planId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/plans/$planId/activate',
    );
    return TreatmentPlanModel.fromJson(response.data!);
  }

  /// Pause a treatment plan.
  Future<TreatmentPlanModel> pausePlan(String planId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/plans/$planId/pause',
    );
    return TreatmentPlanModel.fromJson(response.data!);
  }

  /// Complete a treatment plan.
  Future<TreatmentPlanModel> completePlan(String planId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/plans/$planId/complete',
    );
    return TreatmentPlanModel.fromJson(response.data!);
  }

  // --- Exercises ---

  /// Get list of exercises.
  Future<List<ExerciseModel>> getExercises({
    ExerciseCategory? category,
    BodyPart? bodyPart,
    int? difficulty,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/exercises',
      queryParameters: {
        if (category != null) 'category': category.name,
        if (bodyPart != null) 'body_part': bodyPart.name,
        if (difficulty != null) 'difficulty': difficulty,
      },
    );
    return response.data!
        .map((json) => ExerciseModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific exercise.
  Future<ExerciseModel> getExercise(String exerciseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/exercises/$exerciseId',
    );
    return ExerciseModel.fromJson(response.data!);
  }

  /// Create a new exercise.
  Future<ExerciseModel> createExercise({
    required String name,
    String description = '',
    String instructions = '',
    ExerciseCategory category = ExerciseCategory.mobility,
    BodyPart bodyPart = BodyPart.knee,
    int difficultyLevel = 1,
    String? videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    Map<String, dynamic> sensorConfig = const {},
    Map<String, dynamic> metricsConfig = const {},
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/exercises',
      data: {
        'name': name,
        'description': description,
        'instructions': instructions,
        'category': category.name,
        'body_part': bodyPart.name,
        'difficulty_level': difficultyLevel,
        if (videoUrl != null) 'video_url': videoUrl,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        'sensor_config': sensorConfig,
        'metrics_config': metricsConfig,
      },
    );
    return ExerciseModel.fromJson(response.data!);
  }
}

@Riverpod(keepAlive: true)
TherapistRepository therapistRepository(Ref ref) {
  return TherapistRepository(dio: ref.watch(dioProvider));
}
