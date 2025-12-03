import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:speedview/user/constants.dart';

import 'models/meeting.dart';

const Duration _networkTimeout = Duration(seconds: 12);

class MeetingService {
  MeetingService({http.Client? client}) : _client = client ?? http.Client();

  static const String _path = '/meeting/api/';
  final http.Client _client;

  Future<MeetingListResponse> fetchMeetings({
    String query = '',
    int page = 1,
  }) async {
    final uri = _buildUri(query: query, page: page);

    try {
      final response = await _client.get(uri).timeout(_networkTimeout);
      if (response.statusCode != 200) {
        throw MeetingException(
          'Failed to fetch meetings (HTTP ${response.statusCode})',
        );
      }
      final parsed = meetingListResponseFromJson(response.body);
      if (!parsed.ok) {
        throw MeetingException('SpeedView API returned an error.');
      }
      return parsed;
    } on TimeoutException {
      throw MeetingException('Request timed out. Please try again.');
    } on MeetingException {
      rethrow;
    } catch (e) {
      throw MeetingException('Unexpected error: $e');
    }
  }

  Uri _buildUri({required String query, required int page}) {
    final params = <String, String>{'page': page.toString()};
    if (query.isNotEmpty) {
      params['q'] = query;
    }
    final baseUri = Uri.parse(speedViewBaseUrl);
    final path = baseUri.path.endsWith('/')
        ? '${baseUri.path.substring(0, baseUri.path.length - 1)}$_path'
        : '${baseUri.path}$_path';
    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: path,
      queryParameters: params,
    );
  }

  void dispose() => _client.close();
}

class MeetingException implements Exception {
  MeetingException(this.message);

  final String message;

  @override
  String toString() => message;
}
