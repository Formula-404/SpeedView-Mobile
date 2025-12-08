import 'dart:convert';

class SessionResponse {
  final bool ok;
  final List<MeetingData> data;
  final PaginationData? pagination;
  final String? error;

  SessionResponse({
    required this.ok,
    required this.data,
    this.pagination,
    this.error,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    if (json['ok'] == false) {
      return SessionResponse(
        ok: false,
        data: [],
        error: json['error'],
      );
    }
    return SessionResponse(
      ok: true,
      data: List<MeetingData>.from(json['data'].map((x) => MeetingData.fromJson(x))),
      pagination: json['pagination'] != null ? PaginationData.fromJson(json['pagination']) : null,
    );
  }
}

class PaginationData {
  final int currentPage;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;
  final int totalMeetings;

  PaginationData({
    required this.currentPage,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
    required this.totalMeetings,
  });

  factory PaginationData.fromJson(Map<String, dynamic> json) => PaginationData(
    currentPage: json['current_page'],
    totalPages: json['total_pages'],
    hasPrevious: json['has_previous'],
    hasNext: json['has_next'],
    totalMeetings: json['total_meetings'],
  );
}

class MeetingData {
  final MeetingInfo meetingInfo;
  final List<Session> sessions;

  MeetingData({required this.meetingInfo, required this.sessions});

  factory MeetingData.fromJson(Map<String, dynamic> json) => MeetingData(
    meetingInfo: MeetingInfo.fromJson(json['meeting_info']),
    sessions: List<Session>.from(json['sessions'].map((x) => Session.fromJson(x))),
  );
}

class MeetingInfo {
  final int meetingKey;
  final String meetingName;
  final String circuitShortName;
  final String countryName;
  final int year;

  MeetingInfo({
    required this.meetingKey,
    required this.meetingName,
    required this.circuitShortName,
    required this.countryName,
    required this.year,
  });

  factory MeetingInfo.fromJson(Map<String, dynamic> json) => MeetingInfo(
    meetingKey: json['meeting_key'] ?? 0,
    meetingName: json['meeting_name'],
    circuitShortName: json['circuit_short_name'],
    countryName: json['country_name'],
    year: json['year'],
  );
}

class Session {
  final int sessionKey;
  final String sessionName;
  final DateTime? dateStart;
  final String dateStartStr;

  Session({
    required this.sessionKey,
    required this.sessionName,
    this.dateStart,
    required this.dateStartStr,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    sessionKey: json['session_key'] ?? 0,
    sessionName: json['session_name'] ?? "Unknown Session",
    dateStart: json['date_start'] != null ? DateTime.parse(json['date_start']) : null,
    dateStartStr: json['date_start_str'] ?? "N/A",
  );
}