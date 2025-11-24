import 'dart:convert';

MeetingListResponse meetingListResponseFromJson(String source) =>
    MeetingListResponse.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );

/// Represents the API response returned by `/meeting/api/`.
class MeetingListResponse {
  MeetingListResponse({
    required this.ok,
    required this.meetings,
    required this.pagination,
    required this.meetingKeys,
  });

  factory MeetingListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    return MeetingListResponse(
      ok: json['ok'] as bool? ?? false,
      meetings: data
          .map((dynamic item) =>
              Meeting.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: MeetingPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
      meetingKeys: (json['meeting_keys'] as List<dynamic>? ?? [])
          .map((dynamic v) => int.tryParse(v.toString()) ?? 0)
          .toList(),
    );
  }

  final bool ok;
  final List<Meeting> meetings;
  final MeetingPagination pagination;
  final List<int> meetingKeys;
}

class Meeting {
  const Meeting({
    required this.meetingKey,
    required this.meetingName,
    required this.circuitShortName,
    required this.countryName,
    required this.location,
    required this.year,
    required this.dateStartLabel,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
        meetingKey: json['meeting_key']?.toString() ?? '-',
        meetingName: json['meeting_name'] as String? ?? 'Unknown Meeting',
        circuitShortName: json['circuit_short_name'] as String? ?? 'Circuit',
        countryName: json['country_name'] as String? ?? 'Unknown Country',
        location: json['location'] as String? ?? 'Unknown Location',
        year: json['year']?.toString() ?? '-',
        dateStartLabel: json['date_start_str'] as String? ?? 'N/A',
      );

  final String meetingKey;
  final String meetingName;
  final String circuitShortName;
  final String countryName;
  final String location;
  final String year;
  final String dateStartLabel;
}

class MeetingPagination {
  const MeetingPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalMeetings,
    required this.hasPrevious,
    required this.hasNext,
  });

  factory MeetingPagination.fromJson(Map<String, dynamic> json) =>
      MeetingPagination(
        currentPage: json['current_page'] as int? ?? 1,
        totalPages: json['total_pages'] as int? ?? 1,
        totalMeetings: json['total_meetings'] as int? ?? 0,
        hasPrevious: json['has_previous'] as bool? ?? false,
        hasNext: json['has_next'] as bool? ?? false,
      );

  final int currentPage;
  final int totalPages;
  final int totalMeetings;
  final bool hasPrevious;
  final bool hasNext;
}
