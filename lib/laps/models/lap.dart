class Lap {
  final String? dateStartStr;
  final int? driverNumber;
  final int? lapNumber;
  final double? sector1;
  final double? sector2;
  final double? sector3;
  final double? lapDuration;
  final double? i1Speed;
  final double? i2Speed;
  final double? stSpeed;
  final bool isPitOutLap;

  Lap({
    this.dateStartStr,
    this.driverNumber,
    this.lapNumber,
    this.sector1,
    this.sector2,
    this.sector3,
    this.lapDuration,
    this.i1Speed,
    this.i2Speed,
    this.stSpeed,
    required this.isPitOutLap,
  });

  factory Lap.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      return double.tryParse(v.toString());
    }

    return Lap(
      dateStartStr: json['date_start_str'] as String?,
      driverNumber: json['driver_number'] as int?,
      lapNumber: json['lap_number'] as int?,
      sector1: _toDouble(json['duration_sector_1']),
      sector2: _toDouble(json['duration_sector_2']),
      sector3: _toDouble(json['duration_sector_3']),
      lapDuration: _toDouble(json['lap_duration']),
      i1Speed: _toDouble(json['i1_speed']),
      i2Speed: _toDouble(json['i2_speed']),
      stSpeed: _toDouble(json['st_speed']),
      isPitOutLap: json['is_pit_out_lap'] == true,
    );
  }
}
