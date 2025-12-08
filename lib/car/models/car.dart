class CarTelemetryEntry {
  CarTelemetryEntry({
    required this.id,
    required this.driverNumber,
    this.meetingKey,
    this.sessionKey,
    this.sessionName,
    this.date,
    this.speed,
    this.throttle,
    this.brake,
    this.nGear,
    this.rpm,
    this.drs,
    this.drsState,
    this.createdAt,
    this.updatedAt,
    this.sessionOffsetSeconds,
    this.isManual = false,
  });

  factory CarTelemetryEntry.fromJson(Map<String, dynamic> json) {
    return CarTelemetryEntry(
      id: json['id']?.toString() ?? '',
      driverNumber: _parseInt(json['driver_number']) ?? 0,
      meetingKey: _parseInt(json['meeting_key']),
      sessionKey: _parseInt(json['session_key']),
      sessionName: json['session_name'] as String?,
      date: _parseDate(json['date']),
      speed: _parseInt(json['speed']),
      throttle: _parseInt(json['throttle']),
      brake: _parseInt(json['brake']),
      nGear: _parseInt(json['n_gear']),
      rpm: _parseInt(json['rpm']),
      drs: _parseInt(json['drs']),
      drsState: json['drs_state'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      sessionOffsetSeconds: _parseInt(json['session_offset_seconds']),
      isManual: _parseBool(json['is_manual']),
    );
  }

  final String id;
  final int driverNumber;
  final int? meetingKey;
  final int? sessionKey;
  final String? sessionName;
  final DateTime? date;
  final int? speed;
  final int? throttle;
  final int? brake;
  final int? nGear;
  final int? rpm;
  final int? drs;
  final String? drsState;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? sessionOffsetSeconds;
  final bool isManual;

  String get driverLabel => '#$driverNumber';

  bool get isDrsActive {
    const activeCodes = {10, 12, 14};
    if (drs != null && activeCodes.contains(drs)) {
      return true;
    }
    final label = (drsState ?? '').toLowerCase();
    return label.contains('on');
  }

  String get drsLabel => drsState ?? (drs?.toString() ?? 'Unknown');
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}
