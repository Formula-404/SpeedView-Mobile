import 'package:flutter/material.dart';

import '../models/car.dart';
import 'car_stat_chip.dart';

class CarDetailSheet extends StatelessWidget {
  const CarDetailSheet({super.key, required this.entry});

  final CarTelemetryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF05070B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Driver ${entry.driverLabel}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Meeting ${entry.meetingKey ?? '-'} • Session ${entry.sessionName ?? entry.sessionKey ?? '-'}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CarStatChip(
                  label: 'Recorded at',
                  value: _formatDateTime(entry.date),
                  icon: Icons.schedule,
                ),
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
                  icon: Icons.downhill_skiing_rounded,
                ),
                CarStatChip(
                  label: 'Gear',
                  value: entry.nGear?.toString() ?? '-',
                  icon: Icons.settings_input_component_rounded,
                ),
                CarStatChip(
                  label: 'RPM',
                  value: entry.rpm != null ? '${entry.rpm} rpm' : 'Unknown',
                  icon: Icons.donut_small,
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
            const SizedBox(height: 24),
            Text(
              'Metadata',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildMetadataRow('Entry ID', entry.id),
            _buildMetadataRow('Meeting Key', entry.meetingKey?.toString() ?? '-'),
            _buildMetadataRow('Session Key', entry.sessionKey?.toString() ?? '-'),
            _buildMetadataRow('Created At', _formatDateTime(entry.createdAt)),
            _buildMetadataRow('Updated At', _formatDateTime(entry.updatedAt)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime? date) {
  if (date == null) return 'N/A';
  final local = date.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d • $h:$min';
}
