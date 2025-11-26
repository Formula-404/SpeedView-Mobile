import 'package:flutter/material.dart';

import '../models/car.dart';
import 'car_stat_chip.dart';

class CarTelemetryCard extends StatelessWidget {
  const CarTelemetryCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  final CarTelemetryEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = _formatDate(entry.date);
    final sessionLabel =
        entry.sessionName ?? entry.sessionKey?.toString() ?? 'No session';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
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
              color: Colors.black.withValues(alpha: .45),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildDriverBadge(theme),
                const Spacer(),
                Text(
                  dateLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              sessionLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CarStatChip(
                  label: 'Speed',
                  value: entry.speed != null ? '${entry.speed} km/h' : 'N/A',
                  icon: Icons.speed,
                ),
                CarStatChip(
                  label: 'Throttle',
                  value:
                      entry.throttle != null ? '${entry.throttle}%' : 'Unknown',
                  icon: Icons.keyboard_double_arrow_up_rounded,
                ),
                CarStatChip(
                  label: 'Brake',
                  value: entry.brake != null ? '${entry.brake}%' : 'Unknown',
                  icon: Icons.downhill_skiing_outlined,
                ),
                CarStatChip(
                  label: 'Gear & RPM',
                  value:
                      '${entry.nGear ?? '-'} • ${entry.rpm != null ? '${entry.rpm} rpm' : 'Unknown'}',
                  icon: Icons.donut_large,
                ),
                CarStatChip(
                  label: 'DRS',
                  value: entry.drsLabel,
                  icon: Icons.air_rounded,
                  accentColor:
                      entry.isDrsActive ? const Color(0xFF4ADE80) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverBadge(ThemeData theme) {
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
            entry.driverLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Unknown time';
  final local = date.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d • $h:$min';
}
