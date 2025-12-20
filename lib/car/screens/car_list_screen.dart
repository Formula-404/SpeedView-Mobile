import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/common/constants.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/theme/typography.dart';
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
  final TextEditingController _meetingKeyController = TextEditingController();
  final TextEditingController _sessionKeyController = TextEditingController();
  final List<CarTelemetryEntry> _entries = [];
  bool _loading = false;
  String? _error;
  DateTime? _lastFetchedAt;
  CarDrsFilter _drsFilter = CarDrsFilter.all;
  bool _isAdmin = false;
  bool _hasRequestedData = false;
  int? _activeMeetingKey;
  int? _activeSessionKey;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminStatus();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _meetingKeyController.dispose();
    _sessionKeyController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() => setState(() {});

  Future<void> _openManualEntries() async {
    if (!_isAdmin) return;
    await Navigator.of(context).pushNamed(AppRoutes.carManual);
    if (!mounted) return;
    if (_activeMeetingKey != null) {
      await _refreshCurrentQuery();
    }
  }

  Future<void> _fetchEntriesForFilters({
    required int meetingKey,
    int? sessionKey,
  }) async {
    final request = context.read<CookieRequest>();
    if (!request.loggedIn) {
      setState(() {
        _error = 'Please log in to view car data.';
        _entries.clear();
        _loading = false;
        _isAdmin = false;
        _hasRequestedData = true;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _hasRequestedData = true;
    });

    try {
      final repo = CarRepository(request);
      final results = await repo.fetchMeetingEntries(
        meetingKey: meetingKey,
        sessionKey: sessionKey,
      );
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(results);
        _lastFetchedAt = DateTime.now();
        _loading = false;
        _activeMeetingKey = meetingKey;
        _activeSessionKey = sessionKey;
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

  Future<void> _loadTelemetryFromForm() async {
    final meetingText = _meetingKeyController.text.trim();
    final meetingKey = int.tryParse(meetingText);
    if (meetingKey == null) {
      _showInputError('Meeting key must be a number.');
      return;
    }

    final sessionText = _sessionKeyController.text.trim();
    int? sessionKey;
    if (sessionText.isNotEmpty) {
      sessionKey = int.tryParse(sessionText);
      if (sessionKey == null) {
        _showInputError('Session key must be a number.');
        return;
      }
    }

    await _fetchEntriesForFilters(
      meetingKey: meetingKey,
      sessionKey: sessionKey,
    );
  }

  Future<void> _refreshCurrentQuery() async {
    final meetingKey = _activeMeetingKey;
    if (meetingKey == null) {
      return;
    }
    await _fetchEntriesForFilters(
      meetingKey: meetingKey,
      sessionKey: _activeSessionKey,
    );
  }

  Future<void> _checkAdminStatus() async {
    final request = context.read<CookieRequest>();
    if (!request.loggedIn) {
      setState(() {
        _isAdmin = false;
        if (!_hasRequestedData) {
          _loading = false;
        }
      });
      return;
    }

    try {
      final response = await request.get(buildSpeedViewUrl('/profile-flutter/'));
      if (!mounted) return;
      final role = response['role']?.toString().toLowerCase();
      setState(() {
        _isAdmin = role == 'admin';
        if (!_hasRequestedData) {
          _loading = false;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        if (!_hasRequestedData) {
          _loading = false;
        }
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
          onRefresh: _refreshCurrentQuery,
          backgroundColor: const Color(0xFF0F151E),
          color: const Color(0xFFFB4D46),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildFilterCard(),
              const SizedBox(height: 20),
              if (_hasRequestedData) ...[
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildDrsFilters(),
                const SizedBox(height: 20),
                _buildSummary(),
                const SizedBox(height: 12),
              ],
              if (!_hasRequestedData && !_loading)
              _buildInitialState(),
              if (_loading) _buildLoadingState(),
              if (!_loading && _error != null) _buildErrorState(),
              if (_hasRequestedData && !_loading && _error == null && _filteredEntries.isEmpty)
                _buildEmptyState(),
              if (_hasRequestedData && !_loading && _error == null && _filteredEntries.isNotEmpty)
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

  Widget _buildHeader(BuildContext context) {
    final breadcrumbStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: .6),
        ) ??
        TextStyle(color: Colors.white.withValues(alpha: .6));
    final breadcrumbActive = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text('Home', style: breadcrumbStyle),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text('Car Telemetry', style: breadcrumbActive),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Car Telemetry Explorer',
          style: speedViewHeadingStyle(
            context,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter a meeting key to fetch telemetry data.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildFilterCard() {
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
          Text(
            'Meeting filter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _meetingKeyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Meeting key',
              hintText: 'e.g. 1219',
              filled: true,
              fillColor: Color(0xFF0F151E),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sessionKeyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Session key (optional)',
              hintText: 'e.g. 9493',
              filled: true,
              fillColor: Color(0xFF0F151E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loadTelemetryFromForm,
                  icon: const Icon(Icons.sync),
                  label: const Text('Load telemetry'),
                ),
              ),
              if (_isAdmin) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _openManualEntries,
                  icon: const Icon(Icons.engineering_outlined),
                  label: const Text('Manual data'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        color: const Color(0xFF0F151E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Choose a meeting to begin',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Enter a meeting key then tap "Load telemetry" to fetch data. '
            'Use a session key if you want to focus on a single session.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
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

    final meetingLabel =
        _activeMeetingKey != null ? '#$_activeMeetingKey' : 'Not selected';
    final sessionLabel = _activeSessionKey?.toString() ?? 'All sessions';

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
          Text(
            'Meeting $meetingLabel • Session $sessionLabel',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
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
            onPressed: _refreshCurrentQuery,
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
            'No telemetry for this filter.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try another meeting key or session, then refresh the data on SpeedView web if needed.',
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

  void _showInputError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
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
