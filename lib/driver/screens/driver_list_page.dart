import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

import '../models/driver.dart';
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

  // UI state
  bool _gridMode = true;

  static const _baseUrl = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitial);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await _fetchProfile();
    await _fetchDrivers();
  }

  Future<void> _fetchProfile() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get("$_baseUrl/profile-flutter/");
      if (response is Map && response['status'] == true && response['role'] == 'admin') {
        setState(() => _isAdmin = true);
      }
    } catch (_) {
      // ignore (anggap bukan admin)
    }
  }

  Future<void> _fetchDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final request = context.read<CookieRequest>();
    try {
      final response = await request.get("$_baseUrl/driver/api/mobile/");
      if (response is! Map || response['ok'] != true) {
        throw Exception((response is Map ? response['error'] : null) ?? 'Failed to load drivers');
      }

      final List<dynamic> data = (response['data'] as List?) ?? <dynamic>[];
      final drivers = data.map((e) => Driver.fromJson(e as Map<String, dynamic>)).toList();

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
      return;
    }

    _filtered = _drivers.where((d) {
      final combined = [
        d.fullName,
        d.broadcastName,
        d.countryCode,
        d.driverNumber.toString(),
        d.teams.join(' '),
      ].join(' ').toLowerCase();
      return combined.contains(q);
    }).toList();
  }

  Future<void> _openForm({Driver? driver}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DriverFormPage(existing: driver)),
    );

    if (changed == true) {
      await _fetchDrivers();
    }
  }

  Future<void> _openDetail(Driver driver) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DriverDetailPage(driver: driver, isAdmin: _isAdmin)),
    );

    if (changed == true) {
      await _fetchDrivers();
    }
  }

  Future<void> _confirmDelete(Driver driver) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text(
          'Delete Driver',
          style: TextStyle(
            color: Color(0xFFE6EDF3),
            fontWeight: FontWeight.w700,
          ),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        "$_baseUrl/driver/api/mobile/${driver.driverNumber}/delete/",
        jsonEncode(<String, String>{}),
      );

      if (response is Map && (response['ok'] == true || response['deleted'] != null)) {
        setState(() {
          _drivers.removeWhere((d) => d.driverNumber == driver.driverNumber);
          _applyFilter();
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver #${driver.driverNumber} deleted'),
            backgroundColor: Colors.green[700],
          ),
        );
        return;
      }

      throw Exception(response is Map ? (response['error'] ?? 'Failed to delete') : 'Failed to delete');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete driver: $e'),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      drawer: const SpeedViewDrawer(currentRoute: AppRoutes.drivers),
      appBar: SpeedViewAppBar(
        title: 'Drivers',
        actions: [
          IconButton(
            tooltip: _gridMode ? 'Switch to list' : 'Switch to grid',
            onPressed: () => setState(() => _gridMode = !_gridMode),
            icon: Icon(_gridMode ? Icons.view_agenda_outlined : Icons.grid_view_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _fetchDrivers,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackRow(context),
              const SizedBox(height: 14),

              Row(
                children: [
                  _buildMetricChip(label: 'Total', value: _drivers.length.toString()),
                  const SizedBox(width: 8),
                  _buildMetricChip(label: 'Visible', value: _filtered.length.toString()),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      _gridMode ? 'Grid view' : 'List view',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

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
                          MaterialPageRoute(builder: (_) => const LapsListPage()),
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
                          MaterialPageRoute(builder: (_) => const PitListPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _searchController,
                onChanged: (_) => setState(_applyFilter),
                style: const TextStyle(color: Color(0xFFE6EDF3)),
                decoration: InputDecoration(
                  hintText: 'Search: number, name, country, team…',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _searchController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _applyFilter();
                          }),
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.red))
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No drivers found.',
                                  style: TextStyle(color: Color(0xFFE6EDF3), fontSize: 16),
                                ),
                              )
                            : _gridMode
                                ? _buildGrid()
                                : _buildList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              onPressed: _fetchDrivers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 520 ? 3 : 2;

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final d = _filtered[index];
        return _DriverMiniCard(
          driver: d,
          isAdmin: _isAdmin,
          onTap: () => _openDetail(d),
          onEdit: _isAdmin ? () => _openForm(driver: d) : null,
          onDelete: _isAdmin ? () => _confirmDelete(d) : null,
        );
      },
    );
  }

  Widget _buildList() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final d = _filtered[index];
        return _DriverRowCard(
          driver: d,
          isAdmin: _isAdmin,
          onTap: () => _openDetail(d),
          onEdit: _isAdmin ? () => _openForm(driver: d) : null,
          onDelete: _isAdmin ? () => _confirmDelete(d) : null,
        );
      },
    );
  }

  Widget _buildBackRow(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Back to Home',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2933), Color(0xFF111827)],
        ),
        border: Border.all(color: Colors.white24.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFF7A5A),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
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
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
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
}

class _DriverMiniCard extends StatelessWidget {
  final Driver driver;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _DriverMiniCard({
    required this.driver,
    required this.isAdmin,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = driver.displayName;
    final cc = (driver.countryCode).trim().toUpperCase();
    final broadcast = (driver.broadcastName).trim();
    final teams = driver.teams;

    String subtitle = '';
    if (broadcast.isNotEmpty && broadcast.toLowerCase() != name.toLowerCase()) {
      subtitle = broadcast;
    } else if (cc.isNotEmpty) {
      subtitle = cc;
    } else {
      subtitle = 'Driver profile';
    }

    final teamLine = teams.isEmpty
        ? 'No team data'
        : (teams.length == 1 ? teams.first : '${teams.first} +${teams.length - 1}');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F141B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _DriverAvatarBadge(
                  imageUrl: driver.headshotUrl,
                  name: name,
                  number: driver.driverNumber,
                  size: 44,
                ),
                const Spacer(),
                if (isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white60, size: 18),
                    color: const Color(0xFF0D1117),
                    onSelected: (v) {
                      if (v == 'edit') onEdit?.call();
                      if (v == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit', style: TextStyle(color: Color(0xFFE6EDF3))),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE6EDF3),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(Icons.groups_2_outlined, size: 16, color: Colors.red[300]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      teamLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverRowCard extends StatelessWidget {
  final Driver driver;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _DriverRowCard({
    required this.driver,
    required this.isAdmin,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = driver.displayName;
    final cc = (driver.countryCode).trim().toUpperCase();
    final teams = driver.teams;

    final teamLine = teams.isEmpty
        ? 'No team data'
        : (teams.length == 1 ? teams.first : '${teams.first} +${teams.length - 1}');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F141B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            _DriverAvatarBadge(
              imageUrl: driver.headshotUrl,
              name: name,
              number: driver.driverNumber,
              size: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (cc.isNotEmpty) ...[
                        const Icon(Icons.flag_outlined, size: 14, color: Colors.white60),
                        const SizedBox(width: 6),
                        Text(cc, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        const SizedBox(width: 10),
                      ],
                      const Icon(Icons.groups_2_outlined, size: 14, color: Colors.white60),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          teamLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isAdmin)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white60, size: 18),
                color: const Color(0xFF0D1117),
                onSelected: (v) {
                  if (v == 'edit') onEdit?.call();
                  if (v == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit', style: TextStyle(color: Color(0xFFE6EDF3))),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DriverAvatarBadge extends StatelessWidget {
  final String imageUrl;
  final String name;
  final int number;
  final double size;

  const _DriverAvatarBadge({
    required this.imageUrl,
    required this.name,
    required this.number,
    required this.size,
  });

  bool get _hasValidUrl {
    final u = imageUrl.trim();
    final uri = Uri.tryParse(u);
    return u.isNotEmpty &&
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'D';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final badgeText = '#$number';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
            color: const Color(0xFF0D1117),
          ),
          child: ClipOval(
            child: _hasValidUrl
                ? Image.network(
                    imageUrl.trim(),
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (_, __, ___) => _fallback(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  )
                : _fallback(),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.red.shade700.withOpacity(0.22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.red.shade700.withOpacity(0.45)),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Color(0xFFE6EDF3),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Center(
      child: Text(
        _initials,
        style: const TextStyle(
          color: Color(0xFFE6EDF3),
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}
