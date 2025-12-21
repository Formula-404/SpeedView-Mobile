import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/common/constants.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/theme/typography.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

import '../models/car.dart';
import '../models/car_driver_session_group.dart';
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
  final Set<String> _expandedGroups = <String>{};

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
        _expandedGroups.clear();
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
      final manualEntries = await _fetchManualTelemetryForMeeting(
        repository: repo,
        meetingKey: meetingKey,
        sessionKey: sessionKey,
      );
      final mergedEntries = _mergeEntries(results, manualEntries);
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(mergedEntries);
        _lastFetchedAt = DateTime.now();
        _loading = false;
        _activeMeetingKey = meetingKey;
        _activeSessionKey = sessionKey;
        _expandedGroups.clear();
      });
    } on CarRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _entries.clear();
        _loading = false;
        _expandedGroups.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _entries.clear();
        _loading = false;
        _expandedGroups.clear();
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

  @override
  Widget build(BuildContext context) {
    final searchQuery = _CarSearchQuery.fromRaw(_searchController.text);
    final sessionGroups = _hasRequestedData
        ? _buildSessionGroups(searchQuery)
        : const <CarSessionGroup>[];
    final hasRenderableGroups =
        _hasRequestedData && !_loading && _error == null && sessionGroups.isNotEmpty;

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
                _buildSummary(sessionGroups),
                const SizedBox(height: 12),
              ],
              if (!_hasRequestedData && !_loading)
              _buildInitialState(),
              if (_loading) _buildLoadingState(),
              if (!_loading && _error != null) _buildErrorState(),
              if (_hasRequestedData && !_loading && _error == null && sessionGroups.isEmpty)
                _buildEmptyState(),
              if (hasRenderableGroups) ..._buildSessionSections(sessionGroups),
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
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home),
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
          hintText: 'Use session#9493 or driver#44 to filter results...',
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

  Widget _buildSummary(List<CarSessionGroup> sessionGroups) {
    final sessionCount = sessionGroups.length;
    final driverCount = sessionGroups.fold<int>(
      0,
      (total, session) => total + session.driverGroups.length,
    );
    final allEntries = sessionGroups
        .expand((session) => session.driverGroups)
        .expand((group) => group.entries)
        .toList();
    final totalSamples = allEntries.length;
    final avgSpeed =
        _averageInt(allEntries.map((entry) => entry.speed));
    final drsActiveCount = allEntries.where((entry) => entry.isDrsActive).length;
    final syncedAt = _lastFetchedAt;

    final meetingLabel =
        _activeMeetingKey != null ? '#$_activeMeetingKey' : 'Not selected';
    final sessionLabel = _activeSessionKey?.toString() ?? 'All sessions';
    final avgSpeedLabel =
        avgSpeed != null ? '${avgSpeed.round()} km/h' : '—';
    final drsShare = totalSamples == 0
        ? 'DRS active: —'
        : 'DRS active: ${(drsActiveCount / totalSamples * 100).round()}%';

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
              Expanded(child: _buildSummaryTile('Sessions', '$sessionCount')),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryTile('Driver profiles', '$driverCount'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryTile('Telemetry samples', '$totalSamples'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Avg speed: $avgSpeedLabel • $drsShare',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (syncedAt != null) ...[
            const SizedBox(height: 8),
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

  List<Widget> _buildSessionSections(List<CarSessionGroup> sessions) {
    return sessions
        .map(
          (session) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSessionHeader(session),
              const SizedBox(height: 12),
              ...session.driverGroups.map((group) {
                final id = group.id;
                return CarDriverSessionCard(
                  group: group,
                  expanded: _expandedGroups.contains(id),
                  onToggle: () => _toggleGroup(id),
                  onEntryTap: _showDetail,
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        )
        .toList();
  }

  Widget _buildSessionHeader(CarSessionGroup session) {
    final theme = Theme.of(context);
    final driverCount = session.driverGroups.length;
    final driverLabel =
        driverCount == 1 ? '1 driver' : '$driverCount drivers';
    final keyLabel =
        session.sessionKey != null ? '#${session.sessionKey}' : 'No key';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session.sessionLabel,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Session key $keyLabel • $driverLabel',
          style:
              theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  void _toggleGroup(String id) {
    setState(() {
      if (_expandedGroups.contains(id)) {
        _expandedGroups.remove(id);
      } else {
        _expandedGroups.add(id);
      }
    });
  }

  Future<List<CarTelemetryEntry>> _fetchManualTelemetryForMeeting({
    required CarRepository repository,
    required int meetingKey,
    int? sessionKey,
  }) async {
    try {
      final manualEntries = await repository.fetchManualEntries(limit: 500);
      return manualEntries.where((entry) {
        final matchesMeeting = entry.meetingKey == meetingKey ||
            (entry.meetingKey == null &&
                sessionKey != null &&
                entry.sessionKey == sessionKey);
        final matchesSession =
            sessionKey == null || entry.sessionKey == sessionKey;
        return matchesMeeting && matchesSession;
      }).toList();
    } on CarRepositoryException catch (e) {
      debugPrint('Manual telemetry fetch failed: ${e.message}');
      return const [];
    } catch (e) {
      debugPrint('Manual telemetry fetch failed: $e');
      return const [];
    }
  }

  List<CarTelemetryEntry> _mergeEntries(
    List<CarTelemetryEntry> primary,
    List<CarTelemetryEntry> manual,
  ) {
    final merged = <String, CarTelemetryEntry>{};
    for (final entry in primary) {
      merged[entry.id] = entry;
    }
    for (final entry in manual) {
      merged[entry.id] = entry;
    }
    final list = merged.values.toList();
    list.sort((a, b) {
      final aSession = a.sessionKey ?? 0;
      final bSession = b.sessionKey ?? 0;
      final sessionCompare = bSession.compareTo(aSession);
      if (sessionCompare != 0) return sessionCompare;
      final aDate = a.date?.millisecondsSinceEpoch ?? 0;
      final bDate = b.date?.millisecondsSinceEpoch ?? 0;
      return bDate.compareTo(aDate);
    });
    return list;
  }

  List<CarSessionGroup> _buildSessionGroups(_CarSearchQuery query) {
    final filteredEntries =
        _entries.where(_matchesDrsFilter).toList();
    final sessionMap = <int?, Map<int, List<CarTelemetryEntry>>>{};

    for (final entry in filteredEntries) {
      final driverMap = sessionMap.putIfAbsent(
        entry.sessionKey,
        () => <int, List<CarTelemetryEntry>>{},
      );
      final driverEntries = driverMap.putIfAbsent(
        entry.driverNumber,
        () => <CarTelemetryEntry>[],
      );
      driverEntries.add(entry);
    }

    final sessions = <CarSessionGroup>[];
    sessionMap.forEach((sessionKey, driverMap) {
      final driverGroups = <CarDriverSessionGroup>[];
      driverMap.forEach((driverNumber, entries) {
        if (entries.isEmpty) return;
        final sortedEntries = List<CarTelemetryEntry>.from(entries)
          ..sort((a, b) {
            final aTime = a.date?.millisecondsSinceEpoch ?? 0;
            final bTime = b.date?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });
        final first = sortedEntries.first;
        final group = CarDriverSessionGroup(
          sessionKey: first.sessionKey,
          sessionName: first.sessionName,
          driverNumber: driverNumber,
          entries: sortedEntries,
        );
        if (query.matches(group)) {
          driverGroups.add(group);
        }
      });
      driverGroups.sort((a, b) => a.driverNumber.compareTo(b.driverNumber));
      if (driverGroups.isNotEmpty) {
        final sessionNameCandidate = driverGroups.firstWhere(
          (group) => group.sessionName != null && group.sessionName!.isNotEmpty,
          orElse: () => driverGroups.first,
        );
        sessions.add(
          CarSessionGroup(
            sessionKey: sessionKey,
            sessionName: sessionNameCandidate.sessionName,
            driverGroups: driverGroups,
          ),
        );
      }
    });

    sessions.sort((a, b) {
      final aKey = a.sessionKey ?? 0;
      final bKey = b.sessionKey ?? 0;
      final keyCompare = bKey.compareTo(aKey);
      if (keyCompare != 0) return keyCompare;
      final aLabel = a.sessionName ?? '';
      final bLabel = b.sessionName ?? '';
      return aLabel.compareTo(bLabel);
    });
    return sessions;
  }

  bool _matchesDrsFilter(CarTelemetryEntry entry) {
    return switch (_drsFilter) {
      CarDrsFilter.all => true,
      CarDrsFilter.active => entry.isDrsActive,
      CarDrsFilter.inactive => !entry.isDrsActive,
    };
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

double? _averageInt(Iterable<int?> values) {
  var sum = 0;
  var count = 0;
  for (final value in values) {
    if (value != null) {
      sum += value;
      count++;
    }
  }
  if (count == 0) return null;
  return sum / count;
}

class _CarSearchQuery {
  _CarSearchQuery({
    required this.sessionKeys,
    required this.driverNumbers,
    required this.text,
  });

  factory _CarSearchQuery.fromRaw(String raw) {
    final normalized = raw.toLowerCase();
    final sessionKeys = <int>{};
    final driverNumbers = <int>{};
    var remaining = normalized;

    final tokenRegex = RegExp(r'(session|driver)#([0-9]+)');
    for (final match in tokenRegex.allMatches(normalized)) {
      final token = match.group(0);
      final type = match.group(1);
      final value = int.tryParse(match.group(2) ?? '');
      if (value != null) {
        if (type == 'session') {
          sessionKeys.add(value);
        } else if (type == 'driver') {
          driverNumbers.add(value);
        }
      }
      if (token != null) {
        remaining = remaining.replaceFirst(token, ' ');
      }
    }

    final cleaned = remaining.trim().replaceAll(RegExp(r'\s+'), ' ');
    return _CarSearchQuery(
      sessionKeys: sessionKeys,
      driverNumbers: driverNumbers,
      text: cleaned,
    );
  }

  final Set<int> sessionKeys;
  final Set<int> driverNumbers;
  final String text;

  bool matches(CarDriverSessionGroup group) {
    if (sessionKeys.isNotEmpty) {
      final sessionKey = group.sessionKey;
      if (sessionKey == null || !sessionKeys.contains(sessionKey)) {
        return false;
      }
    }
    if (driverNumbers.isNotEmpty &&
        !driverNumbers.contains(group.driverNumber)) {
      return false;
    }
    if (text.isEmpty) return true;

    final haystacks = <String>[
      group.driverNumber.toString(),
      group.sessionKey?.toString() ?? '',
      group.sessionName ?? '',
    ].map((value) => value.toLowerCase());

    return haystacks.any((value) => value.contains(text));
  }
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
