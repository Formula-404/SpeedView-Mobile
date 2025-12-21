import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/car.dart';
import '../models/car_driver_session_group.dart';
import 'car_stat_chip.dart';

class CarDriverSessionCard extends StatelessWidget {
  const CarDriverSessionCard({
    super.key,
    required this.group,
    required this.expanded,
    required this.onToggle,
    this.onEntryTap,
  });

  final CarDriverSessionGroup group;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<CarTelemetryEntry>? onEntryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        gradient: const LinearGradient(
          colors: [Color(0xFF101726), Color(0xFF0C1119)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _DriverBadge(driverLabel: group.driverLabel),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.sessionName?.isNotEmpty == true
                                  ? group.sessionName!
                                  : (group.sessionKey != null
                                      ? 'Session ${group.sessionKey}'
                                      : 'Session unknown'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              group.stats.sampleCount == 1
                                  ? '1 telemetry sample'
                                  : '${group.stats.sampleCount} telemetry samples',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white60,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      CarStatChip(
                        label: 'Avg speed',
                        value: _formatStat(group.stats.avgSpeed, 'km/h'),
                        icon: Icons.speed,
                      ),
                      CarStatChip(
                        label: 'Top speed',
                        value: _formatInt(group.stats.maxSpeed, suffix: ' km/h'),
                        icon: Icons.flag_circle,
                      ),
                      CarStatChip(
                        label: 'Throttle',
                        value: _formatStat(group.stats.avgThrottle, '%'),
                        icon: Icons.keyboard_double_arrow_up_rounded,
                      ),
                      CarStatChip(
                        label: 'Brake',
                        value: _formatStat(group.stats.avgBrake, '%'),
                        icon: Icons.downhill_skiing_outlined,
                      ),
                      CarStatChip(
                        label: 'RPM',
                        value: _formatStat(group.stats.avgRpm, ' rpm'),
                        icon: Icons.donut_large,
                      ),
                      CarStatChip(
                        label: 'DRS active',
                        value: _formatStat(
                          group.stats.drsActivePercentage,
                          '%',
                          decimals: 1,
                        ),
                        icon: Icons.air,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _DriverTelemetryList(
              entries: group.entries,
              onEntryTap: onEntryTap,
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

class _DriverBadge extends StatelessWidget {
  const _DriverBadge({required this.driverLabel});

  final String driverLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF141B2C),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_motorsports, color: Colors.white70, size: 18),
          const SizedBox(width: 6),
          Text(
            driverLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _DriverTelemetryList extends StatelessWidget {
  const _DriverTelemetryList({
    required this.entries,
    this.onEntryTap,
  });

  final List<CarTelemetryEntry> entries;
  final ValueChanged<CarTelemetryEntry>? onEntryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: Colors.white.withValues(alpha: .12),
            height: 1,
          ),
          const SizedBox(height: 16),
          ...entries.map(
            (entry) => _TelemetryEntryTile(
              entry: entry,
              onTap: onEntryTap != null ? () => onEntryTap!(entry) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryEntryTile extends StatelessWidget {
  const _TelemetryEntryTile({required this.entry, this.onTap});

  final CarTelemetryEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestampLabel = _formatTimestamp(entry.date);
    final drsActive = entry.isDrsActive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF0D1422),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Text(
                  timestampLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.air_rounded,
                  size: 16,
                  color: drsActive
                      ? const Color(0xFF4ADE80)
                      : Colors.white.withValues(alpha: .6),
                ),
                const SizedBox(width: 4),
                Text(
                  entry.drsLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.white54,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _EntryStat(label: 'Speed', value: _formatInt(entry.speed, suffix: ' km/h')),
                _EntryStat(label: 'Throttle', value: _formatInt(entry.throttle, suffix: '%')),
                _EntryStat(label: 'Brake', value: _formatInt(entry.brake, suffix: '%')),
                _EntryStat(label: 'Gear', value: entry.nGear?.toString() ?? '—'),
                _EntryStat(label: 'RPM', value: _formatInt(entry.rpm)),
                _EntryStat(
                  label: 'Offset',
                  value: entry.sessionOffsetSeconds != null
                      ? '${entry.sessionOffsetSeconds}s'
                      : '—',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryStat extends StatelessWidget {
  const _EntryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

String _formatStat(double? value, String suffix, {int decimals = 0}) {
  if (value == null) return '—';
  final formatted = decimals == 0
      ? value.round().toString()
      : value.toStringAsFixed(decimals);
  final trimmed = decimals == 0
      ? formatted
      : formatted.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return '$trimmed $suffix'.trim();
}

String _formatInt(int? value, {String suffix = ''}) {
  if (value == null) return '—';
  return '$value$suffix'.trim();
}

String _formatTimestamp(DateTime? date) {
  if (date == null) return 'Unknown';
  final local = date.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d • $h:$min';
}
