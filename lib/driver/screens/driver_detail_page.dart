// lib/driver/screens/driver_detail_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/driver.dart';
import 'driver_form_page.dart';

// modul read-only
import 'package:speedview/laps/screens/laps_list_page.dart';
import 'package:speedview/pit/screens/pit_list_page.dart';

class DriverDetailPage extends StatefulWidget {
  final Driver driver;
  final bool isAdmin;

  const DriverDetailPage({
    super.key,
    required this.driver,
    this.isAdmin = false,
  });

  @override
  State<DriverDetailPage> createState() => _DriverDetailPageState();
}

class _DriverDetailPageState extends State<DriverDetailPage> {
  late Driver _driver;
  bool _isDeleting = false;
  static const _baseUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    _driver = widget.driver;
  }

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    final request = context.read<CookieRequest>();

    try {
      final response = await request.postJson(
        "$_baseUrl/driver/api/${_driver.driverNumber}/delete/",
        jsonEncode(<String, String>{}),
      );

      if (response['ok'] == true || response['deleted'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Driver #${_driver.driverNumber} deleted successfully'),
              backgroundColor: Colors.green[700],
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to delete');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete driver: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DriverFormPage(existing: _driver),
      ),
    );

    if (changed == true) {
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = _driver;

    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      appBar: AppBar(
        title: Text(
          driver.displayName,
          style: const TextStyle(color: Color(0xFFE6EDF3)),
        ),
        backgroundColor: const Color(0xFF161B22),
        iconTheme: const IconThemeData(color: Color(0xFFE6EDF3)),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _edit,
            ),
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isDeleting ? null : _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======= CTA LAPS & PIT (PALING ATAS) =======
            Row(
              children: [
                Expanded(
                  child: _buildCtaCard(
                    icon: Icons.timeline,
                    title: 'Laps',
                    subtitle: 'See lap times & sectors',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LapsListPage(
                              // kalau nanti LapsListPage punya filter driver,
                              // kamu bisa kirim driver.driverNumber di sini
                              ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCtaCard(
                    icon: Icons.ev_station_outlined,
                    title: 'Pit Stops',
                    subtitle: 'Pit duration & timing',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PitListPage(
                              // sama seperti Laps: bisa dikirim driver_number
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ======= FOTO DRIVER BESAR =======
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: driver.hasHeadshot
                    ? Image.network(
                        driver.headshotUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _fallbackImageLarge(context),
                      )
                    : _fallbackImageLarge(context),
              ),
            ),
            const SizedBox(height: 20),

            // ======= NAMA + NOMOR =======
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${driver.driverNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    driver.displayName,
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ======= INFO SINGKAT =======
            _infoRow(
              'Country',
              driver.countryCode.isEmpty ? '—' : driver.countryCode,
            ),
            const SizedBox(height: 4),
            _infoRow('Teams', driver.displayTeams),
            const SizedBox(height: 4),
            if (driver.createdAt != null)
              _infoRow(
                'Created',
                driver.createdAt!.toLocal().toString().split('.').first,
              ),
            if (driver.updatedAt != null)
              _infoRow(
                'Updated',
                driver.updatedAt!.toLocal().toString().split('.').first,
              ),
            const SizedBox(height: 24),

            const Text(
              'Overview',
              style: TextStyle(
                color: Color(0xFFE6EDF3),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This section can be extended later with biography, statistics, or additional data from the backend.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white24.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade700.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.red.shade300, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE6EDF3),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackImageLarge(BuildContext context) {
    return Container(
      color: const Color(0xFF111827),
      alignment: Alignment.center,
      child: const Icon(
        Icons.speed,
        color: Colors.white24,
        size: 72,
      ),
    );
  }
}
