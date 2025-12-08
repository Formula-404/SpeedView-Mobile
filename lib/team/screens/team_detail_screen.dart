import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:speedview/user/constants.dart';
import 'team_form_screen.dart';
import '../models/team.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamName;
  final bool isAdmin;

  const TeamDetailScreen({
    super.key,
    required this.teamName,
    this.isAdmin = false,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  Team? _team;
  bool _loading = true;
  String? _error;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeam();
    });
  }

  Future<void> _loadTeam() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final request = context.read<CookieRequest>();

    try {
      final response = await request.get(
        buildSpeedViewUrl('/team/api/${Uri.encodeComponent(widget.teamName)}/')
      );

      if (response['ok'] != true) {
        throw Exception(response['error'] ?? 'Failed to load team');
      }

      final data = response['data'] as Map<String, dynamic>;
      final team = Team.fromJson(data);

      if (!mounted) return;
      setState(() {
        _team = team;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _team = null;
      });
    }
  }

  Color _parseHexColor(String hex) {
    if (hex.isEmpty) return Colors.transparent;
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) return Colors.transparent;
    return Color(int.parse('FF$clean', radix: 16));
  }

  String _msToClock(int? ms) {
    if (ms == null || ms <= 0) return '—';
    final totalMs = ms;
    final minutes = totalMs ~/ 60000;
    final seconds = (totalMs % 60000) ~/ 1000;
    final millis = totalMs % 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
  }

  String _fmtInt(int? v) {
    if (v == null) return '0';
    return v.toString();
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return d.toLocal().toString();
  }

  List<String> _enginesChips(String csv) {
    return csv
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _confirmDelete() async {
    if (!widget.isAdmin) return;

    final team = _team;
    if (team == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B0F14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Team',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${team.teamName}"?\nThis action cannot be undone.',
          style: const TextStyle(color: Color(0xCCFFFFFF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTeam(team.teamName);
    }
  }

  Future<void> _deleteTeam(String teamName) async {
    setState(() {
      _deleting = true;
    });

    final request = context.read<CookieRequest>();
    String? error;

    try {
      final response = await request.post(
        buildSpeedViewUrl('/team/api/${Uri.encodeComponent(teamName)}/delete/'), 
        {}
      );

      if (response['ok'] == true) {
         if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }
      
      error = response['error'] ?? 'Failed to delete team.';

    } catch (e) {
      error = 'Network error while deleting: $e';
    }

    if (!mounted) return;
    setState(() {
      _deleting = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamName = widget.teamName;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                ),
              )
            : _error != null
                ? _ErrorView(
                    teamName: teamName,
                    error: _error!,
                    onRetry: _loadTeam,
                  )
                : _team == null
                    ? _ErrorView(
                        teamName: teamName,
                        error: 'No team data returned from server.',
                        onRetry: _loadTeam,
                      )
                    : _buildDetail(context, _team!),
      ),
    );
  }


  Widget _buildDetail(BuildContext context, Team team) {
    final primaryColor = _parseHexColor(team.teamColourHex.isNotEmpty
        ? team.teamColourHex
        : '#EF4444');
    final secondaryColor = team.teamColourSecondaryHex.isNotEmpty
        ? _parseHexColor(team.teamColourSecondaryHex)
        : _parseHexColor(team.teamColourSecondary);

    final heroBg = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor.withOpacity(0.15),
        Colors.transparent,
      ],
    );

    final countryBaseParts = <String>[];
    if (team.country.isNotEmpty) countryBaseParts.add(team.country);
    if (team.base.isNotEmpty) countryBaseParts.add(team.base);
    final countryBase = countryBaseParts.isEmpty
        ? '—'
        : countryBaseParts.join(' • ');

    final engines = _enginesChips(team.engines);

    return RefreshIndicator(
      onRefresh: _loadTeam,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    team.teamName.isNotEmpty ? team.teamName : widget.teamName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      color: const Color(0xFF0D1117),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(gradient: heroBg),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLogo(team, primaryColor),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            team.teamName.isNotEmpty
                                                ? team.teamName
                                                : 'Unknown Team',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.15),
                                            ),
                                          ),
                                          child: Text(
                                            team.shortCode.isNotEmpty
                                                ? team.shortCode
                                                : '—',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildActiveBadge(team.isActive),
                                        if (widget.isAdmin) ...[
                                          const SizedBox(width: 8),
                                          _buildAdminButtons(team),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      countryBase,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xCCFFFFFF),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        if (team.website.isNotEmpty)
                                          _linkChip(
                                            label: 'Website',
                                            url: team.website,
                                          ),
                                        if (team.website.isNotEmpty &&
                                            team.wikiUrl.isNotEmpty)
                                          const SizedBox(width: 8),
                                        if (team.wikiUrl.isNotEmpty)
                                          _linkChip(
                                            label: 'Wikipedia',
                                            url: team.wikiUrl,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117).withOpacity(0.9),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _colorMetaTile(
                                    label: 'Primary color',
                                    color: primaryColor,
                                    value: team.teamColourHex.isNotEmpty
                                        ? team.teamColourHex
                                        : '—',
                                  ),
                                  const SizedBox(width: 12),
                                  _colorMetaTile(
                                    label: 'Secondary color',
                                    color: secondaryColor,
                                    value: (team.teamColourSecondaryHex
                                                .isNotEmpty ||
                                            team.teamColourSecondary
                                                .isNotEmpty)
                                        ? (team.teamColourSecondaryHex
                                                .isNotEmpty
                                            ? team.teamColourSecondaryHex
                                            : '#${team.teamColourSecondary}')
                                        : '—',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Founded',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0x99FFFFFF),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      team.foundedYear > 0
                                          ? team.foundedYear.toString()
                                          : '—',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Engines',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (engines.isEmpty)
                              const Text(
                                'No engine data.',
                                style: TextStyle(
                                  color: Color(0x99FFFFFF),
                                  fontSize: 13,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: engines
                                    .map(
                                      (e) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        child: Text(
                                          e,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xCCFFFFFF),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              team.teamDescription.isNotEmpty
                                  ? team.teamDescription
                                  : 'No description provided.',
                              style: const TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Career Stats',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _statCard(
                              label: 'Races entered',
                              value: _fmtInt(team.racesEntered),
                            ),
                            _statCard(
                              label: 'Wins',
                              value: _fmtInt(team.raceVictories),
                            ),
                            _statCard(
                              label: 'Podiums',
                              value: _fmtInt(team.podiums),
                            ),
                            _statCard(
                              label: 'Points',
                              value: _fmtInt(team.points),
                            ),
                            _statCard(
                              label: 'Constructors’ titles',
                              value:
                                  _fmtInt(team.constructorsChampionships),
                            ),
                            _statCard(
                              label: 'Drivers’ titles',
                              value: _fmtInt(team.driversChampionships),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Performance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _statCard(
                              label: 'Average lap',
                              value: _msToClock(team.avgLapTimeMs),
                            ),
                            _statCard(
                              label: 'Best lap',
                              value: _msToClock(team.bestLapTimeMs),
                            ),
                            _statCard(
                              label: 'Avg. pit stop',
                              value: _msToClock(team.avgPitDurationMs),
                            ),
                            _statCard(
                              label: 'Top speed',
                              value: team.topSpeedKph > 0
                                  ? '${team.topSpeedKph} kph'
                                  : '—',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '* Lap & pit times formatted as m:ss.mmm',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0x80FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Created: ${_fmtDate(team.createdAt)} • Updated: ${_fmtDate(team.updatedAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0x66FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(Team team, Color primary) {
    final fallback = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: primary == Colors.transparent
            ? Colors.white.withOpacity(0.06)
            : primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        team.shortCode.isNotEmpty
            ? team.shortCode
            : (team.teamName.isNotEmpty ? team.teamName[0] : '?'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );

    if (team.teamLogoUrl.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        team.teamLogoUrl,
        width: 60,
        height: 60,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  Widget _buildActiveBadge(bool isActive) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x6622C55E)),
          color: const Color(0x1A22C55E),
        ),
        child: const Text(
          'ACTIVE',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF4ADE80),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          color: Colors.white.withOpacity(0.05),
        ),
        child: const Text(
          'INACTIVE',
          style: TextStyle(
            fontSize: 10,
            color: Color(0x99FFFFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  Widget _buildAdminButtons(Team team) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeamFormScreen(team: team),
              ),
            );
            if (result == true) {
              _loadTeam();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(
              Icons.edit,
              size: 16,
              color: Colors.blueAccent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _confirmDelete,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0x26EF4444),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x66EF4444)),
            ),
            child: const Icon(
              Icons.delete,
              size: 16,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
      ],
    );
  }

  Widget _linkChip({required String label, required String url}) {
    // TODO: Launch URL
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link, size: 12, color: Colors.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorMetaTile({
    required String label,
    required Color color,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color == Colors.transparent
                  ? Colors.transparent
                  : color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0x99FFFFFF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({required String label, required String value}) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48 - 20) / 2, 
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0x99FFFFFF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String teamName;
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.teamName,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              'Failed to load "$teamName"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
