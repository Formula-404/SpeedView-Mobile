class PitStop {
  final String? dateStr;
  final int? driverNumber;
  final int? lapNumber;
  final double? pitDuration;
  final int? sessionKey;
  final int? meetingKey;

  PitStop({
    this.dateStr,
    this.driverNumber,
    this.lapNumber,
    this.pitDuration,
    this.sessionKey,
    this.meetingKey,
  });

  factory PitStop.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      return double.tryParse(v.toString());
    }

    return PitStop(
      dateStr: json['date_str'] as String?,
      driverNumber: json['driver_number'] as int?,
      lapNumber: json['lap_number'] as int?,
      pitDuration: _toDouble(json['pit_duration']),
      sessionKey: json['session_key'] as int?,
      meetingKey: json['meeting_key'] as int?,
    );
  }
}
