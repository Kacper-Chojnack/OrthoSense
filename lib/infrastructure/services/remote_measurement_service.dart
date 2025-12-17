import 'package:dio/dio.dart';
import 'package:orthosense/features/measurements/data/api/measurement_service.dart';
import 'package:orthosense/features/measurements/domain/models/measurement_model.dart';

/// Real HTTP implementation of [MeasurementService].
/// Communicates with FastAPI backend for measurement sync.
class RemoteMeasurementService implements MeasurementService {
  RemoteMeasurementService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _measurementsPath = '/api/v1/measurements';

  @override
  Future<SyncResponse> postMeasurement(MeasurementModel data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _measurementsPath,
        data: _toRequestBody(data),
      );

      return _parseSyncResponse(response.data!);
    } on DioException catch (e) {
      return _handleDioError(e, data.id);
    }
  }

  @override
  Future<List<SyncResponse>> postMeasurementsBatch(
    List<MeasurementModel> data,
  ) async {
    try {
      final response = await _dio.post<List<dynamic>>(
        '$_measurementsPath/batch',
        data: data.map(_toRequestBody).toList(),
      );

      return response.data!
          .map((item) => _parseSyncResponse(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // Return failure for all items on batch error
      return data
          .map(
            (item) => SyncResponse(
              success: false,
              backendId: item.id,
              errorMessage: _extractErrorMessage(e),
            ),
          )
          .toList();
    }
  }

  Map<String, dynamic> _toRequestBody(MeasurementModel data) {
    return {
      'id': data.id,
      'user_id': data.userId,
      'type': data.type,
      'json_data': data.data,
      'created_at': data.createdAt.toUtc().toIso8601String(),
      if (data.updatedAt != null)
        'updated_at': data.updatedAt!.toUtc().toIso8601String(),
    };
  }

  SyncResponse _parseSyncResponse(Map<String, dynamic> json) {
    return SyncResponse(
      success: json['success'] as bool? ?? false,
      backendId: json['backend_id'] as String? ?? json['id'] as String? ?? '',
      errorMessage: json['error_message'] as String?,
    );
  }

  SyncResponse _handleDioError(DioException e, String measurementId) {
    final errorMessage = _extractErrorMessage(e);
    return SyncResponse(
      success: false,
      backendId: measurementId,
      errorMessage: errorMessage,
    );
  }

  String _extractErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout - server unreachable';
      case DioExceptionType.sendTimeout:
        return 'Request timeout - slow network';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout - server slow';
      case DioExceptionType.connectionError:
        return 'Connection error - check network';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final detail = e.response?.data?['detail'];
        return 'Server error ($statusCode): ${detail ?? e.message}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.badCertificate:
        return 'SSL certificate error';
      case DioExceptionType.unknown:
        return e.message ?? 'Unknown network error';
    }
  }
}
