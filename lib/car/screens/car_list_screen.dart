import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

import '../models/car.dart';
import '../services/car_repository.dart';
import '../widgets/dart.dart';

enum CarDrsFilter { all, active, inactive }

class CarListScreen extends StatefulWidget {
  const CarListScreen({super.key});

  @override
  State<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends State<CarListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<CarTelemetryEntry> _entries = [];
  bool _loading = true;
  String? _error;
  DateTime? _lastFetchedAt;
  CarDrsFilter _drsFilter = CarDrsFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchEntries());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() => setState(() {});

  Future<void> _fetchEntries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final request = context.read<CookieRequest>();
    if (!request.loggedIn) {
      setState(() {
        _error = 'Silakan login untuk melihat data mobil.';
        _entries.clear();
        _loading = false;
      });
      return;
    }

    try {
      final repo = CarRepository(request);
      final results = await repo.fetchEntries();
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(results);
        _lastFetchedAt = DateTime.now();
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

  List<CarTelemetryEntry> get _filteredEntries {
    final query = _searchController.text.trim().toLowerCase();
    return _entries.where((entry) {
      final matchesQuery = query.isEmpty || _matchesQuery(entry, query);
      final matchesFilter = switch (_drsFilter) {
        CarDrsFilter.all => true,
        CarDrsFilter.active => entry.isDrsActive,
        CarDrsFilter.inactive => !entry.isDrsActive,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SpeedViewDrawer(currentRoute: AppRoutes.cars),
      appBar: const SpeedViewAppBar(title: 'Car Telemetry'),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _fetchEntries,
          backgroundColor: const Color(0xFF0F151E),
          color: const Color(0xFFFB4D46),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildDrsFilters(),
              const SizedBox(height: 20),
              _buildSummary(),
              const SizedBox(height: 12),
              if (_loading) _buildLoadingState(),
              if (!_loading && _error != null) _buildErrorState(),
              if (!_loading && _error == null && _filteredEntries.isEmpty)
                _buildEmptyState(),
              if (!_loading && _error == null && _filteredEntries.isNotEmpty)
                ..._filteredEntries.map(
                  (entry) => CarTelemetryCard(
                    entry: entry,
                    onTap: () => _showDetail(entry),
                  ),
                ),
              const SizedBox(height: 24),
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
            const Text(
              'Car Telemetry',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Manual Telemetry Entries',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Entries synced from SpeedView web admin.',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.white70),
          hintText: 'Search by driver, meeting, session, or DRS...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDrsFilters() {
    return Wrap(
      spacing: 10,
      children: CarDrsFilter.values.map((filter) {
        final selected = _drsFilter == filter;
        final label = switch (filter) {
          CarDrsFilter.all => 'All',
          CarDrsFilter.active => 'DRS Active',
          CarDrsFilter.inactive => 'DRS Off',
        };
        return ChoiceChip(
          selected: selected,
          label: Text(label),
          onSelected: (_) => setState(() => _drsFilter = filter),
          selectedColor: const Color(0xFFFB4D46),
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: selected
                  ? const Color(0xFFFB4D46)
                  : Colors.white.withValues(alpha: .1),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummary() {
    final entries = _filteredEntries;
    final total = entries.length;
    final speedSamples = entries.where((entry) => entry.speed != null).toList();
    final avgSpeed = speedSamples.isEmpty
        ? 0
        : speedSamples
                .map((entry) => entry.speed!)
                .fold<int>(0, (a, b) => a + b) ~/
            speedSamples.length;
    final drsActiveCount = entries.where((e) => e.isDrsActive).length;
    final syncedAt = _lastFetchedAt;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        color: const Color(0xFF0C121C),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSummaryTile('Entries', '$total')),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryTile('Avg speed', '$avgSpeed km/h')),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryTile('DRS active', '$drsActiveCount'),
              ),
            ],
          ),
          if (syncedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last sync: ${_formatTimestamp(syncedAt)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 130,
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
            'Unable to load car telemetry',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _fetchEntries,
            child: const Text('Retry'),
          ),
          if (_error != null && _error!.toLowerCase().contains('login'))
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login),
              child: const Text('Go to Login'),
            ),
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
            'No telemetry entries yet.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add entries through SpeedView web admin to populate this list.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
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

String _formatTimestamp(DateTime date) {
  final local = date.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}
