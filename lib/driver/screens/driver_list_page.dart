// lib/driver/screens/driver_list_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/driver.dart';
import '../widgets/driver_card.dart';
import 'driver_detail_page.dart';
import 'driver_form_page.dart';

// modul read-only
import 'package:speedview/laps/screens/laps_list_page.dart';
import 'package:speedview/pit/screens/pit_list_page.dart';

class DriverListPage extends StatefulWidget {
  const DriverListPage({super.key});

  @override
  State<DriverListPage> createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Driver> _drivers = [];
  List<Driver> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false;

  static const _baseUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitial);
  }

  Future<void> _loadInitial() async {
    await _fetchProfile();
    await _fetchDrivers();
  }

  Future<void> _fetchProfile() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get("$_baseUrl/profile-flutter/");
      if (response['status'] == true && response['role'] == 'admin') {
        setState(() {
          _isAdmin = true;
        });
      }
    } catch (_) {
      // kalau gagal ambil profile, anggap bukan admin
    }
  }

  Future<void> _fetchDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final request = context.read<CookieRequest>();
    try {
      final response = await request.get("$_baseUrl/driver/api/");
      if (response['ok'] != true) {
        throw Exception(response['error'] ?? 'Failed to load drivers');
      }

      final List<dynamic> data = response['data'] ?? [];
      final drivers =
          data.map((e) => Driver.fromJson(e as Map<String, dynamic>)).toList();

      setState(() {
        _drivers = drivers;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.of(_drivers);
    } else {
      _filtered = _drivers.where((d) {
        final combined = [
          d.fullName,
          d.broadcastName,
          d.countryCode,
          d.driverNumber.toString(),
        ].join(' ').toLowerCase();
        return combined.contains(q);
      }).toList();
    }
  }

  Future<void> _confirmDelete(Driver driver) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text(
          'Delete Driver',
          style: TextStyle(color: Color(0xFFE6EDF3)),
        ),
        content: Text(
          'Are you sure you want to delete ${driver.displayName} (#${driver.driverNumber})?',
          style: const TextStyle(color: Color(0xFFE6EDF3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (yes == true) {
      await _deleteDriver(driver);
    }
  }

  Future<void> _deleteDriver(Driver driver) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        "$_baseUrl/driver/api/${driver.driverNumber}/delete/",
        jsonEncode(<String, String>{}),
      );

      if (response['ok'] == true || response['deleted'] != null) {
        setState(() {
          _drivers.removeWhere(
              (d) => d.driverNumber == driver.driverNumber);
          _applyFilter();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Driver #${driver.driverNumber} deleted'),
              backgroundColor: Colors.green[700],
            ),
          );
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
    }
  }

  Future<void> _openForm({Driver? driver}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DriverFormPage(
          existing: driver,
        ),
      ),
    );

    if (changed == true) {
      await _fetchDrivers();
    }
  }

  Future<void> _openDetail(Driver driver) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DriverDetailPage(driver: driver, isAdmin: _isAdmin),
      ),
    );

    if (changed == true) {
      await _fetchDrivers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      appBar: AppBar(
        title: const Text(
          'Drivers',
          style: TextStyle(color: Color(0xFFE6EDF3)),
        ),
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE6EDF3)),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: Colors.red[700],
              icon: const Icon(Icons.add),
              label: const Text('Add Driver'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _fetchDrivers,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ===== CTA LAPS & PIT (paling atas) =====
              Row(
                children: [
                  Expanded(
                    child: _buildCtaCard(
                      icon: Icons.timeline,
                      title: 'Laps',
                      subtitle: 'Lap times & sectors',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LapsListPage(),
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
                            builder: (_) => const PitListPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // search bar
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(_applyFilter),
                style: const TextStyle(color: Color(0xFFE6EDF3)),
                decoration: InputDecoration(
                  hintText: 'Search driver name, number, or country',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Colors.red),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No drivers found.',
                                  style: TextStyle(
                                    color: Color(0xFFE6EDF3),
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final driver = _filtered[index];
                                  return DriverCard(
                                    driver: driver,
                                    showAdminActions: _isAdmin,
                                    onTap: () => _openDetail(driver),
                                    onEdit: _isAdmin
                                        ? () => _openForm(
                                            driver: driver,
                                          )
                                        : null,
                                    onDelete: _isAdmin
                                        ? () => _confirmDelete(
                                              driver,
                                            )
                                        : null,
                                  );
                                },
                              ),
              ),
            ],
          ),
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
          border: Border.all(
            color: Colors.white24.withOpacity(0.25),
          ),
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
            const Icon(Icons.chevron_right,
                color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}
