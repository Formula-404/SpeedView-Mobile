import 'dart:math';

import 'car.dart';

class CarSessionGroup {
  CarSessionGroup({
    required this.sessionKey,
    required this.sessionName,
    required List<CarDriverSessionGroup> driverGroups,
  }) : driverGroups = List.unmodifiable(driverGroups);

  final int? sessionKey;
  final String? sessionName;
  final List<CarDriverSessionGroup> driverGroups;

  String get sessionLabel {
    if (sessionName != null && sessionName!.isNotEmpty) {
      return sessionName!;
    }
    if (sessionKey != null) {
      return 'Session $sessionKey';
    }
    return 'Unknown session';
  }
}

class CarDriverSessionGroup {
  CarDriverSessionGroup({
    required this.sessionKey,
    required this.sessionName,
    required this.driverNumber,
    required List<CarTelemetryEntry> entries,
  })  : entries = List.unmodifiable(entries),
        stats = CarDriverSessionStats.fromEntries(entries);

  final int? sessionKey;
  final String? sessionName;
  final int driverNumber;
  final List<CarTelemetryEntry> entries;
  final CarDriverSessionStats stats;

  String get id => '${sessionKey ?? 'unknown'}-$driverNumber';

  String get driverLabel => '#$driverNumber';
}

class CarDriverSessionStats {
  const CarDriverSessionStats({
    required this.sampleCount,
    this.avgSpeed,
    this.avgThrottle,
    this.avgBrake,
    this.avgRpm,
    this.maxSpeed,
    this.drsActivePercentage,
    this.firstSampleAt,
    this.lastSampleAt,
  });

  factory CarDriverSessionStats.fromEntries(List<CarTelemetryEntry> entries) {
    var sumSpeed = 0;
    var speedCount = 0;
    var sumThrottle = 0;
    var throttleCount = 0;
    var sumBrake = 0;
    var brakeCount = 0;
    var sumRpm = 0;
    var rpmCount = 0;
    int? topSpeed;
    DateTime? first;
    DateTime? last;
    var drsActive = 0;

    for (final entry in entries) {
      final speed = entry.speed;
      if (speed != null) {
        sumSpeed += speed;
        speedCount++;
        topSpeed = topSpeed == null ? speed : max(topSpeed, speed);
      }

      final throttle = entry.throttle;
      if (throttle != null) {
        sumThrottle += throttle;
        throttleCount++;
      }

      final brake = entry.brake;
      if (brake != null) {
        sumBrake += brake;
        brakeCount++;
      }

      final rpm = entry.rpm;
      if (rpm != null) {
        sumRpm += rpm;
        rpmCount++;
      }

      if (entry.isDrsActive) {
        drsActive++;
      }

      final timestamp = entry.date;
      if (timestamp != null) {
        first = first == null || timestamp.isBefore(first) ? timestamp : first;
        last = last == null || timestamp.isAfter(last) ? timestamp : last;
      }
    }

    double? _avg(int sum, int count) =>
        count == 0 ? null : sum / count;

    final sampleCount = entries.length;
    final drsPercentage =
        sampleCount == 0 ? null : (drsActive / sampleCount) * 100;

    return CarDriverSessionStats(
      sampleCount: sampleCount,
      avgSpeed: _avg(sumSpeed, speedCount),
      avgThrottle: _avg(sumThrottle, throttleCount),
      avgBrake: _avg(sumBrake, brakeCount),
      avgRpm: _avg(sumRpm, rpmCount),
      maxSpeed: topSpeed,
      drsActivePercentage: drsPercentage,
      firstSampleAt: first,
      lastSampleAt: last,
    );
  }

  final int sampleCount;
  final double? avgSpeed;
  final double? avgThrottle;
  final double? avgBrake;
  final double? avgRpm;
  final int? maxSpeed;
  final double? drsActivePercentage;
  final DateTime? firstSampleAt;
  final DateTime? lastSampleAt;
}
