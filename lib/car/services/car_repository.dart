import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:speedview/user/constants.dart';

import '../models/car.dart';

class CarRepository {
  CarRepository(this.request);

  final CookieRequest request;

  Future<List<CarTelemetryEntry>> fetchMeetingEntries({
    required int meetingKey,
    int? sessionKey,
    int limit = 500,
  }) async {
    final params = <String, String>{
      'meeting_key': meetingKey.toString(),
      'limit': limit.toString(),
    };
    if (sessionKey != null) {
      params['session_key'] = sessionKey.toString();
    }
    final query = Uri(queryParameters: params).query;
    final uri = buildSpeedViewUrl('/car/json/?$query');
    final response = await request.get(uri);
    return _parseListResponse(response, errorMessage: 'Failed to load telemetry.');
  }

  Future<List<CarTelemetryEntry>> fetchManualEntries({int limit = 200}) async {
    final uri = buildSpeedViewUrl('/car/manual/json/?limit=$limit');
    final response = await request.get(uri);
    return _parseListResponse(response, errorMessage: 'Failed to load manual telemetry.');
  }

  Future<CarTelemetryEntry> createManualEntry({
    int? meetingKey,
    required int sessionKey,
    required int driverNumber,
    required int speed,
    required int throttle,
    required int brake,
    required int nGear,
    required int rpm,
    required int drs,
    int sessionOffsetSeconds = 0,
  }) async {
    final uri = buildSpeedViewUrl('/car/telemetry/create-ajax/');
    final payload = _buildManualPayload(
      meetingKey: meetingKey,
      sessionKey: sessionKey,
      driverNumber: driverNumber,
      speed: speed,
      throttle: throttle,
      brake: brake,
      nGear: nGear,
      rpm: rpm,
      drs: drs,
      sessionOffsetSeconds: sessionOffsetSeconds,
    );
    final response = await request.post(uri, payload);
    return _parseEntryResponse(
      response,
      defaultMessage: 'Failed to add car telemetry.',
    );
  }

  Future<CarTelemetryEntry> updateManualEntry({
    required String entryId,
    int? meetingKey,
    required int sessionKey,
    required int driverNumber,
    required int speed,
    required int throttle,
    required int brake,
    required int nGear,
    required int rpm,
    required int drs,
    int sessionOffsetSeconds = 0,
  }) async {
    final carId = _parseEntryId(entryId);
    final uri = buildSpeedViewUrl('/car/telemetry/$carId/update-ajax/');
    final payload = _buildManualPayload(
      meetingKey: meetingKey,
      sessionKey: sessionKey,
      driverNumber: driverNumber,
      speed: speed,
      throttle: throttle,
      brake: brake,
      nGear: nGear,
      rpm: rpm,
      drs: drs,
      sessionOffsetSeconds: sessionOffsetSeconds,
    );
    final response = await request.post(uri, payload);
    return _parseEntryResponse(
      response,
      defaultMessage: 'Failed to update car telemetry.',
    );
  }

  Future<void> deleteManualEntry(String entryId) async {
    final carId = _parseEntryId(entryId);
    final uri = buildSpeedViewUrl('/car/telemetry/$carId/delete-ajax/');
    final response = await request.post(uri, const <String, String>{});
    if (response is Map<String, dynamic> && response['success'] == true) {
      return;
    }
    final message = response is Map<String, dynamic>
        ? response['message'] ?? response['error'] ?? 'Failed to delete entry.'
        : 'Failed to delete entry.';
    throw CarRepositoryException(message.toString());
  }

  Map<String, String> _buildManualPayload({
    int? meetingKey,
    required int sessionKey,
    required int driverNumber,
    required int speed,
    required int throttle,
    required int brake,
    required int nGear,
    required int rpm,
    required int drs,
    required int sessionOffsetSeconds,
  }) {
    final payload = <String, String>{
      'session_key': sessionKey.toString(),
      'driver_number': driverNumber.toString(),
      'speed': speed.toString(),
      'throttle': throttle.toString(),
      'brake': brake.toString(),
      'n_gear': nGear.toString(),
      'rpm': rpm.toString(),
      'drs': drs.toString(),
      'session_offset_seconds': sessionOffsetSeconds.toString(),
    };
    if (meetingKey != null) {
      payload['meeting_key'] = meetingKey.toString();
    }
    return payload;
  }

  List<CarTelemetryEntry> _parseListResponse(
    dynamic response, {
    required String errorMessage,
  }) {
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(CarTelemetryEntry.fromJson)
          .toList();
    }
    if (response is Map<String, dynamic>) {
      final message = response['message'] ??
          response['detail'] ??
          response['error'] ??
          errorMessage;
      throw CarRepositoryException(message.toString());
    }
    throw CarRepositoryException(errorMessage);
  }

  CarTelemetryEntry _parseEntryResponse(
    dynamic response, {
    required String defaultMessage,
  }) {
    if (response is Map<String, dynamic>) {
      if (response['success'] == true && response['car'] is Map) {
        final payload =
            Map<String, dynamic>.from(response['car'] as Map<dynamic, dynamic>);
        return CarTelemetryEntry.fromJson(payload);
      }
      final message = response['message'] ??
          _formatFormErrors(response['errors']) ??
          defaultMessage;
      throw CarRepositoryException(message.toString());
    }
    throw CarRepositoryException(defaultMessage);
  }

  int _parseEntryId(String entryId) {
    final parsed = int.tryParse(entryId);
    if (parsed == null) {
      throw CarRepositoryException('Invalid entry id: $entryId');
    }
    return parsed;
  }
}

class CarRepositoryException implements Exception {
  CarRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

String? _formatFormErrors(dynamic errors) {
  if (errors is Map) {
    final parts = <String>[];
    errors.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        parts.add('$key: ${value.first}');
      } else if (value != null) {
        parts.add('$key: $value');
      }
    });
    if (parts.isNotEmpty) {
      return parts.join('\n');
    }
  }
  return null;
}
