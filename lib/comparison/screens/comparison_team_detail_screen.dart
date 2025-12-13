import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:speedview/user/constants.dart';
import '../models/Comparison.dart';
import '../models/ComparisonDetail.dart';

class ComparisonTeamDetailScreen extends StatefulWidget {
  const ComparisonTeamDetailScreen({
    Key? key,
    required this.comparison,
    this.apiBaseUrl = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id',
  }) : super(key: key);

  final Comparison comparison;
  final String apiBaseUrl;

  @override
  State<ComparisonTeamDetailScreen> createState() =>
      _ComparisonTeamDetailScreenState();
}

class _ComparisonTeamDetailScreenState
    extends State<ComparisonTeamDetailScreen> {
  late Future<List<ComparisonTeamItem>> _future;

  // local mutable view-state, so we don't mutate widget.comparison (which is final)
  late String _title;
  late bool _isPublic;

  // profile info fetched from backend
  String _currentUsername = '';
  String _currentRole = '';
  bool _profileLoaded = false;

  bool get _canManage {
    if (!_profileLoaded) return false;
    if (_currentRole == 'admin') return true;
    if (_currentUsername.isEmpty) return false;
    return _currentUsername == widget.comparison.ownerName;
  }

  @override
  void initState() {
    super.initState();
    _title = widget.comparison.title;
    _isPublic = widget.comparison.isPublic;
    _future = _loadDetail();
  }

  // need context -> use didChangeDependencies to fetch profile once
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileLoaded) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final request = context.read<CookieRequest>();
      final res = await request.get(buildSpeedViewUrl('/profile-flutter/'));
      setState(() {
        _currentUsername = (res['username'] as String?) ?? '';
        _currentRole = (res['role'] as String?) ?? '';
        _profileLoaded = true;
      });
    } catch (_) {
      // on error, mark as loaded but with empty values (no manage permission)
      setState(() {
        _profileLoaded = true;
      });
    }
  }

  Future<List<ComparisonTeamItem>> _loadDetail() async {
    final uri = Uri.parse(
      '${widget.apiBaseUrl}/comparison/api/${widget.comparison.id}/',
    );

    final res = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception('Failed with status ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['ok'] != true) {
      throw Exception(body['error'] ?? 'Failed to load comparison detail');
    }

    final data = body['data'] as Map<String, dynamic>? ?? {};
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => ComparisonTeamItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _showEditDialog() async {
    final controller = TextEditingController(text: _title);
    bool localIsPublic = _isPublic;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Comparison',
            style: TextStyle(
              color: Color(0xFFE6EDF3),
              fontWeight: FontWeight.w600,
            ),
          ),
          content: StatefulBuilder(
            builder: (ctx, setLocalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Color(0xFFE6EDF3)),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: const TextStyle(
                        color: Color(0x99E6EDF3),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF161B22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF374151),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF374151),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: localIsPublic,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (v) {
                          setLocalState(() {
                            localIsPublic = v ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Make this comparison public',
                          style: TextStyle(
                            color: Color(0xE6E6EDF3),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0x99E6EDF3)),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await _submitEdit(controller.text.trim(), localIsPublic);
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFFE5E7EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Comparison',
            style: TextStyle(
              color: Color(0xFFE6EDF3),
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this comparison? This action cannot be undone.',
            style: TextStyle(
              color: Color(0xE6E6EDF3),
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0x99E6EDF3)),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await _submitDelete();
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitEdit(String newTitle, bool isPublic) async {
    if (!mounted) return;

    final request = context.read<CookieRequest>();

    final url = buildSpeedViewUrl(
      '/comparison/api/mobile/${widget.comparison.id}/edit/',
    );

    final payload = {
      'title': newTitle,
      'is_public': isPublic,
    };

    try {
      final response = await request.postJson(url, jsonEncode(payload));

      if (response['ok'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _title = (data['title'] as String?) ?? _title;
          _isPublic = (data['is_public'] as bool?) ?? _isPublic;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comparison updated.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final msg = (response['error'] ?? 'Failed to update comparison').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _submitDelete() async {
    if (!mounted) return;

    final request = context.read<CookieRequest>();

    final url = buildSpeedViewUrl(
      '/comparison/api/mobile/${widget.comparison.id}/delete/',
    );

    try {
      final response = await request.post(url, {});

      if (response['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comparison deleted.'),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to list after delete
        Navigator.of(context).pop();
      } else {
        final msg =
            (response['error'] ?? 'Failed to delete comparison').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FutureBuilder<List<ComparisonTeamItem>>(
          future: _future,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final error = snapshot.hasError ? snapshot.error.toString() : null;
            final items = snapshot.data ?? const <ComparisonTeamItem>[];

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
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
                              _title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Up to 4 teams, factual overview and a radar stats diagram.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0x99E6EDF3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_canManage) ...[
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _HeaderIconButton(
                                  icon: Icons.edit_outlined,
                                  tooltip: 'Edit comparison',
                                  onTap: _showEditDialog,
                                ),
                                const SizedBox(width: 8),
                                _HeaderIconButton(
                                  icon: Icons.delete_outline,
                                  tooltip: 'Delete comparison',
                                  onTap: _showDeleteDialog,
                                  danger: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (error != null)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 40),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          'Failed to load comparison.\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFF9CA3),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else if (items.isEmpty)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 40),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: const Text(
                          'No team data in this comparison.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xB3E6EDF3),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    _SelectionRow(items: items),
                    const SizedBox(height: 16),
                    _OverviewSection(items: items),
                    const SizedBox(height: 16),
                    _RadarSection(items: items),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  }) : super(key: key);

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final borderColor = danger
        ? const Color(0xFFEF4444).withOpacity(0.7)
        : Colors.white.withOpacity(0.12);
    final bgColor = danger
        ? const Color(0xFF7F1D1D)
        : Colors.white.withOpacity(0.06);
    final iconColor = danger ? const Color(0xFFFCA5A5) : Colors.white;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({required this.items});

  final List<ComparisonTeamItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final t = items[index];
          return Container(
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: t.teamLogoUrl.isNotEmpty
                      ? Image.network(
                          t.teamLogoUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _logoFallback(),
                        )
                      : _logoFallback(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE6EDF3),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          t.country,
                          if (t.base.isNotEmpty) t.base,
                        ].where((e) => e.isNotEmpty).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0x99E6EDF3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _logoFallback() {
    return Container(
      width: 36,
      height: 36,
      color: Colors.white.withOpacity(0.05),
      alignment: Alignment.center,
      child: const Icon(
        Icons.flag_rounded,
        size: 20,
        color: Colors.white70,
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.items});

  final List<ComparisonTeamItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: items.map((t) {
              final color = _RadarSection._parseHex(t.teamColourHex) ??
                  Colors.white.withOpacity(0.4);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withOpacity(0.8),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: t.teamLogoUrl.isNotEmpty
                              ? Image.network(
                                  t.teamLogoUrl,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      _logoMiniFallback(),
                                )
                              : _logoMiniFallback(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.teamName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFE6EDF3),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  t.country,
                                  if (t.base.isNotEmpty) t.base,
                                ].where((e) => e.isNotEmpty).join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0x99E6EDF3),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoRow(context, 'Founded', t.foundedYear?.toString() ?? '—'),
                    _infoRow(context, 'Engines', t.engines.isNotEmpty ? t.engines : '—'),
                    _infoRow(context, 'Website', t.website, isLink: t.website.isNotEmpty),
                    _infoRow(context, 'Wikipedia', t.wikiUrl, isLink: t.wikiUrl.isNotEmpty),
                    _infoRow(context, 'Races entered', t.racesEntered?.toString() ?? '—'),
                    _infoRow(context, 'Wins', t.raceVictories?.toString() ?? '—'),
                    _infoRow(context, 'Podiums', t.podiums?.toString() ?? '—'),
                    _infoRow(context, 'Points', t.points?.toString() ?? '—'),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static Widget _logoMiniFallback() {
    return Container(
      width: 32,
      height: 32,
      color: Colors.white.withOpacity(0.05),
      alignment: Alignment.center,
      child: const Icon(
        Icons.flag_rounded,
        size: 18,
        color: Colors.white70,
      ),
    );
  }

  static void _copyToClipboard(BuildContext context, String url) async {
    final text = url.trim();
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL copied to clipboard'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  static Widget _infoRow(BuildContext context, String label, String value, {bool isLink = false}) {
    final displayValue = isLink ? 'Copy URL' : (value.isNotEmpty ? value : '—');

    final valueStyle = TextStyle(
      color: isLink ? const Color(0xFFEF4444) : const Color(0xFFE6EDF3),
      fontSize: 13,
      decoration: isLink ? TextDecoration.underline : TextDecoration.none,
      fontWeight: isLink ? FontWeight.w600 : FontWeight.normal,
    );

    final content = Text(
      displayValue,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: valueStyle,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0x99E6EDF3),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isLink
                ? InkWell(
                    onTap: () => _copyToClipboard(context, value),
                    child: content,
                  )
                : content,
          ),
        ],
      ),
    );
  }
}

class _RadarSection extends StatelessWidget {
  const _RadarSection({required this.items});

  final List<ComparisonTeamItem> items;

  static const _metrics = [
    _Metric(
      key: 'avgLapTimeMs',
      label: 'Avg lap (ms)',
      invert: true,
      min: 60000,
      max: 120000,
    ),
    _Metric(
      key: 'bestLapTimeMs',
      label: 'Best lap (ms)',
      invert: true,
      min: 55000,
      max: 100000,
    ),
    _Metric(
      key: 'avgPitDurationMs',
      label: 'Avg pit (ms)',
      invert: true,
      min: 1500,
      max: 4000,
    ),
    _Metric(
      key: 'topSpeedKph',
      label: 'Top speed (kph)',
      invert: false,
      min: 250,
      max: 400,
    ),
    _Metric(
      key: 'lapsCompleted',
      label: 'Laps completed',
      invert: false,
      min: 0,
      max: 10000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final datasets = <RadarDataSet>[];

    for (final t in items) {
      final color = _parseHex(t.teamColourHex) ?? Colors.red.shade500;
      final values = <double>[];

      for (final m in _metrics) {
        final raw = _getMetricValue(t, m.key);
        final norm = _normalize(raw, m);
        values.add(norm ?? 0);
      }

      datasets.add(
        RadarDataSet(
          dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
          borderColor: color,
          fillColor: color.withOpacity(0.2),
          entryRadius: 2.5,
          borderWidth: 2,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stats Diagram',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                dataSets: datasets,
                radarBackgroundColor: Colors.transparent,
                radarBorderData: const BorderSide(color: Colors.transparent),
                gridBorderData: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
                tickBorderData: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
                tickCount: 4,
                ticksTextStyle: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 0,
                ),
                getTitle: (index, _) => RadarChartTitle(
                  text: _metrics[index].label,
                  angle: 0,
                ),
                radarShape: RadarShape.polygon,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: items.map((t) {
              final color = _parseHex(t.teamColourHex) ?? Colors.red.shade500;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t.teamName,
                    style: const TextStyle(
                      color: Color(0xE6E6EDF3),
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          const Text(
            'Times are inverted for scoring (lower is better).',
            style: TextStyle(
              fontSize: 11,
              color: Color(0x80E6EDF3),
            ),
          ),
        ],
      ),
    );
  }

  static num? _getMetricValue(ComparisonTeamItem t, String key) {
    switch (key) {
      case 'avgLapTimeMs':
        return t.avgLapTimeMs;
      case 'bestLapTimeMs':
        return t.bestLapTimeMs;
      case 'avgPitDurationMs':
        return t.avgPitDurationMs;
      case 'topSpeedKph':
        return t.topSpeedKph;
      case 'lapsCompleted':
        return t.lapsCompleted;
      default:
        return null;
    }
  }

  static double? _normalize(num? value, _Metric m) {
    if (value == null) return null;
    if (m.max == m.min) return 50;
    final t = ((value - m.min) / (m.max - m.min))
        .clamp(0.0, 1.0)
        .toDouble();
    final base = m.invert ? 1.0 - t : t;
    return base * 100.0;
  }

  static Color? _parseHex(String hex) {
    var h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final value = int.tryParse(h, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}

class _Metric {
  final String key;
  final String label;
  final bool invert;
  final double min;
  final double max;

  const _Metric({
    required this.key,
    required this.label,
    required this.invert,
    required this.min,
    required this.max,
  });
}
