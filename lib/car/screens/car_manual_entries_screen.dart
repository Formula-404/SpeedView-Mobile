import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/common/constants.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

import '../models/car.dart';
import '../services/car_repository.dart';
import '../widgets/car_detail_sheet.dart';
import '../widgets/car_telemetry_card.dart';
import 'car_manual_entry_form.dart';

class CarManualEntriesScreen extends StatefulWidget {
  const CarManualEntriesScreen({super.key});

  @override
  State<CarManualEntriesScreen> createState() => _CarManualEntriesScreenState();
}

class _CarManualEntriesScreenState extends State<CarManualEntriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<CarTelemetryEntry> _entries = [];
  bool _loading = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _checkAdminStatus();
    if (!mounted || !_isAdmin) return;
    await _fetchEntries();
  }

  Future<void> _checkAdminStatus() async {
    final request = context.read<CookieRequest>();
    if (!request.loggedIn) {
      setState(() {
        _isAdmin = false;
        _loading = false;
        _error = 'Login dengan akun admin untuk mengelola manual telemetry.';
      });
      return;
    }

    try {
      final response = await request.get(buildSpeedViewUrl('/profile-flutter/'));
      if (!mounted) return;
      final role = response['role']?.toString().toLowerCase();
      final isAdmin = role == 'admin';
      setState(() {
        _isAdmin = isAdmin;
        if (!isAdmin) {
          _loading = false;
          _error = 'Halaman ini hanya untuk admin.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _loading = false;
        _error = 'Gagal memverifikasi status admin.';
      });
    }
  }

  Future<void> _fetchEntries() async {
    final request = context.read<CookieRequest>();
    if (!request.loggedIn) {
      setState(() {
        _loading = false;
        _error = 'Silakan login terlebih dahulu.';
        _entries.clear();
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = CarRepository(request);
      final results = await repo.fetchManualEntries();
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(results);
        _loading = false;
      });
    } on CarRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _entries.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _entries.clear();
        _loading = false;
      });
    }
  }

  void _handleSearchChanged() => setState(() {});

  Future<void> _openForm({CarTelemetryEntry? entry}) async {
    if (!_isAdmin) return;
    final result = await Navigator.of(context).push<CarTelemetryEntry>(
      MaterialPageRoute(
        builder: (_) => CarManualEntryFormScreen(entry: entry),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        final index = _entries.indexWhere((item) => item.id == result.id);
        if (index >= 0) {
          _entries[index] = result;
        } else {
          _entries.insert(0, result);
        }
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(entry == null
                ? 'Manual telemetry entry created.'
                : 'Manual telemetry entry updated.'),
            backgroundColor: entry == null ? Colors.green : Colors.blueAccent,
          ),
        );
    }
  }

  Future<void> _confirmDelete(CarTelemetryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text(
          'Entry akan dihapus permanen dari daftar manual telemetry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final request = context.read<CookieRequest>();
    final repo = CarRepository(request);
    try {
      await repo.deleteManualEntry(entry.id);
      if (!mounted) return;
      setState(() {
        _entries.removeWhere((item) => item.id == entry.id);
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Entry deleted.'),
            backgroundColor: Colors.redAccent,
          ),
        );
    } on CarRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to delete entry: ${e.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to delete entry: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }

  List<CarTelemetryEntry> get _filteredEntries {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return List.unmodifiable(_entries);
    return _entries
        .where((entry) => _matchesQuery(entry, query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final canRefresh = _isAdmin && _entries.isNotEmpty;
    return Scaffold(
      drawer: const SpeedViewDrawer(currentRoute: AppRoutes.cars),
      appBar: const SpeedViewAppBar(title: 'Manual Car Telemetry'),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFFFB4D46),
              label: const Text('Add manual entry'),
            )
          : null,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: canRefresh ? _fetchEntries : () async {},
          backgroundColor: const Color(0xFF0F151E),
          color: const Color(0xFFFB4D46),
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 24),
              if (_loading) _buildLoadingState(),
              if (!_loading && _error != null) _buildErrorState(),
              if (!_loading && _error == null && _filteredEntries.isEmpty)
                _buildEmptyState(),
              if (!_loading && _error == null && _filteredEntries.isNotEmpty)
                ..._filteredEntries.map(_buildEntryItem),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home),
              child: Text(
                'Home',
                style: TextStyle(color: Colors.white.withValues(alpha: .6)),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text(
              _isAdmin ? 'Manual Data' : 'Manual Data (locked)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _isAdmin
              ? 'Manage manual telemetry entries that sync to SpeedView web admin.'
              : 'Only admins can view and edit manual telemetry entries.',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      enabled: !_loading && _error == null,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Color(0xFF0D1117),
        hintText: 'Search by driver, meeting, or session...',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFF0F151E),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x33FF6B6B)),
        color: const Color(0x33220E0E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unable to load manual telemetry',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(color: Colors.white70),
          ),
          if (_isAdmin) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _fetchEntries,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        color: const Color(0xFF0F151E),
      ),
      child: Column(
        children: const [
          Icon(Icons.inbox_outlined, size: 36, color: Colors.white38),
          SizedBox(height: 12),
          Text(
            'No manual telemetry yet.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Use the button below to add manual entries.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryItem(CarTelemetryEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarTelemetryCard(
          entry: entry,
          onTap: () => _showDetail(entry),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openForm(entry: entry),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirmDelete(entry),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF8A80),
                  side: const BorderSide(color: Color(0xFFFF8A80)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  void _showDetail(CarTelemetryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CarDetailSheet(entry: entry),
    );
  }
}

bool _matchesQuery(CarTelemetryEntry entry, String query) {
  final values = [
    entry.driverNumber.toString(),
    entry.meetingKey?.toString() ?? '',
    entry.sessionKey?.toString() ?? '',
    entry.sessionName?.toLowerCase() ?? '',
    entry.drsLabel.toLowerCase(),
  ];
  return values.any((value) => value.toLowerCase().contains(query));
}
