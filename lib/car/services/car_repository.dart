import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:speedview/user/constants.dart';

import '../models/car.dart';

class CarRepository {
  CarRepository(this.request);

  final CookieRequest request;

  Future<List<CarTelemetryEntry>> fetchEntries({int limit = 200}) async {
    final uri = buildSpeedViewUrl('/car/manual/json/?limit=$limit');
    final response = await request.get(uri);

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
          'Failed to fetch car telemetry.';
      throw CarRepositoryException(message.toString());
    }

    throw CarRepositoryException('Unexpected response from SpeedView API.');
  }
}

class CarRepositoryException implements Exception {
  CarRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
