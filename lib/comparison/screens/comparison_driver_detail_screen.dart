import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:speedview/user/constants.dart';
import '../models/Comparison.dart';
import '../models/ComparisonDetail.dart';

class ComparisonDriverDetailScreen extends StatefulWidget {
  const ComparisonDriverDetailScreen({
    Key? key,
    required this.comparison,
    this.apiBaseUrl = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id',
  }) : super(key: key);

  final Comparison comparison;
  final String apiBaseUrl;

  @override
  State<ComparisonDriverDetailScreen> createState() =>
      _ComparisonDriverDetailScreenState();
}

class _ComparisonDriverDetailScreenState
    extends State<ComparisonDriverDetailScreen> {
  late Future<List<ComparisonDriverItem>> _future;

  late String _title;
  late bool _isPublic;

  String _currentUsername = '';
  String _currentRole = '';
  bool _profileLoaded = false;

  // telemetry state
  String _metric = 'speed';
  final TextEditingController _meetingCtrl = TextEditingController();
  final TextEditingController _sessionCtrl = TextEditingController();
  bool _loadingChart = false;
  String? _chartError;
  List<_DriverSeries> _series = const [];

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
      setState(() {
        _profileLoaded = true;
      });
    }
  }

  Future<List<ComparisonDriverItem>> _loadDetail() async {
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
        .map((e) => ComparisonDriverItem.fromJson(e as Map<String, dynamic>))
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
        final msg =
            (response['error'] ?? 'Failed to update comparison').toString();
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

  Future<void> _loadTelemetry(List<ComparisonDriverItem> items) async {
    final meetingKey = _meetingCtrl.text.trim();
    final sessionKey = _sessionCtrl.text.trim();

    if (meetingKey.isEmpty || sessionKey.isEmpty) {
      setState(() {
        _chartError = 'Enter a meeting and session to load telemetry.';
        _series = const [];
      });
      return;
    }

    setState(() {
      _loadingChart = true;
      _chartError = null;
      _series = const [];
    });

    try {
      final palette = <Color>[
        const Color(0xFFEF4444),
        const Color(0xFF3B82F6),
        const Color(0xFF22C55E),
        const Color(0xFFA855F7),
        const Color(0xFFF59E0B),
        const Color(0xFF14B8A6),
        const Color(0xFFEAB308),
        const Color(0xFF10B981),
      ];

      final List<_DriverSeries> series = [];

      for (var i = 0; i < items.length; i++) {
        final d = items[i];
        final driverNumber = d.number;
        if (driverNumber == null) continue;

        final uri = Uri.parse(
          '${widget.apiBaseUrl}/car/api/grouped/',
        ).replace(queryParameters: {
          'metric': _metric,
          'driver_number': driverNumber.toString(),
          'meeting_key': meetingKey,
          'session_key': sessionKey,
        });

        final res = await http.get(
          uri,
          headers: const {'Accept': 'application/json'},
        );
        if (res.statusCode != 200) continue;
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['ok'] != true) continue;

        final groups = json['groups'] as List<dynamic>? ?? [];
        final grp = groups.firstWhere(
          (g) =>
              int.tryParse('${g['driver_number']}') == driverNumber,
          orElse: () => null,
        );
        if (grp == null) continue;

        final telemetry = grp['telemetry'] as List<dynamic>? ?? [];
        if (telemetry.isEmpty) continue;

        final List<FlSpot> spots = [];
        for (var idx = 0; idx < telemetry.length; idx++) {
          final t = telemetry[idx] as Map<String, dynamic>;
          final v = t[_metric];
          final val = (v is num) ? v.toDouble() : null;
          if (val != null) {
            spots.add(FlSpot(idx.toDouble(), val));
          }
        }

        if (spots.isEmpty) continue;

        final color = palette[i % palette.length];
        final label = '${d.label} (#${driverNumber.toString()})';

        series.add(
          _DriverSeries(
            label: label,
            color: color,
            points: spots,
          ),
        );
      }

      if (series.isEmpty) {
        setState(() {
          _chartError =
              'No telemetry returned for the chosen meeting/session and drivers.';
          _series = const [];
        });
      } else {
        setState(() {
          _chartError = null;
          _series = series;
        });
      }
    } catch (e) {
      setState(() {
        _chartError = 'Failed to load telemetry: $e';
        _series = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingChart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FutureBuilder<List<ComparisonDriverItem>>(
          future: _future,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final error = snapshot.hasError ? snapshot.error.toString() : null;
            final items = snapshot.data ?? const <ComparisonDriverItem>[];

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
                              _title.isNotEmpty
                                  ? _title
                                  : 'Driver Comparison',
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
                              'Compare drivers and overlay telemetry from a session.',
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
                          'No driver data in this comparison.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xB3E6EDF3),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    _DriverSelectionRow(items: items),
                    const SizedBox(height: 16),
                    _DriverTelemetrySection(
                      metric: _metric,
                      onMetricChanged: (m) {
                        setState(() {
                          _metric = m;
                        });
                        _loadTelemetry(items);
                      },
                      meetingController: _meetingCtrl,
                      sessionController: _sessionCtrl,
                      onLoadPressed: () => _loadTelemetry(items),
                      loading: _loadingChart,
                      error: _chartError,
                      series: _series,
                    ),
                    const SizedBox(height: 16),
                    _DriverOverviewSection(items: items),
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

class _DriverSelectionRow extends StatelessWidget {
  const _DriverSelectionRow({required this.items});

  final List<ComparisonDriverItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final d = items[index];
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
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    d.displayNumber,
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    d.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DriverTelemetrySection extends StatelessWidget {
  const _DriverTelemetrySection({
    Key? key,
    required this.metric,
    required this.onMetricChanged,
    required this.meetingController,
    required this.sessionController,
    required this.onLoadPressed,
    required this.loading,
    required this.error,
    required this.series,
  }) : super(key: key);

  final String metric;
  final ValueChanged<String> onMetricChanged;
  final TextEditingController meetingController;
  final TextEditingController sessionController;
  final VoidCallback onLoadPressed;
  final bool loading;
  final String? error;
  final List<_DriverSeries> series;

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
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 120,
                      child: _LabeledDropdown(
                        label: 'Metric',
                        value: metric,
                        items: const [
                          DropdownMenuItem(
                            value: 'speed',
                            child: Text('Speed'),
                          ),
                          DropdownMenuItem(
                            value: 'rpm',
                            child: Text('RPM'),
                          ),
                          DropdownMenuItem(
                            value: 'throttle',
                            child: Text('Throttle'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) onMetricChanged(v);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: _LabeledTextField(
                        label: 'Meeting',
                        controller: meetingController,
                        hintText: 'e.g. 1219',
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: _LabeledTextField(
                        label: 'Session',
                        controller: sessionController,
                        hintText: 'e.g. 3',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: loading ? null : onLoadPressed,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(
                        Icons.refresh,
                        size: 16,
                        color: Colors.white,
                      ),
                    const SizedBox(width: 6),
                    const Text(
                      'Load',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: series.isEmpty
                ? Center(
                    child: Text(
                      error ??
                          'Enter a meeting and session, then tap Load to view telemetry.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0x80E6EDF3),
                        fontSize: 12,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withOpacity(0.12),
                          strokeWidth: 0.5,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.white.withOpacity(0.12),
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (val, meta) => Text(
                              meta.formattedValue,
                              style: const TextStyle(
                                color: Color(0x99E6EDF3),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) =>
                              const Color(0xFF111827).withOpacity(0.9),
                          getTooltipItems: (spots) {
                            return spots.map((s) {
                              final ds = series[s.barIndex];
                              return LineTooltipItem(
                                '${ds.label}\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'x=${s.x.toInt()}  y=${s.y.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: Color(0xFFE5E7EB),
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        for (var i = 0; i < series.length; i++)
                          LineChartBarData(
                            isStrokeCapRound: true,
                            isCurved: true,
                            barWidth: 2,
                            color: series[i].color,
                            dotData: const FlDotData(show: false),
                            spots: series[i].points,
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Each line is a driver in the chosen meeting/session. X axis is sample index.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0x80E6EDF3),
            ),
          ),
          if (error != null && series.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              error!,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFFF9CA3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DriverOverviewSection extends StatelessWidget {
  const _DriverOverviewSection({required this.items});

  final List<ComparisonDriverItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              dataTextStyle: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 12,
              ),
              columnSpacing: 16,
              columns: [
                const DataColumn(
                  label: Text('Attribute'),
                ),
                for (final d in items)
                  DataColumn(
                    label: Text(
                      d.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              rows: [
                DataRow(
                  cells: [
                    const DataCell(
                      Text(
                        'Number',
                        style: TextStyle(
                          color: Color(0x99E6EDF3),
                        ),
                      ),
                    ),
                    for (final d in items)
                      DataCell(
                        Text(d.displayNumber),
                      ),
                  ],
                ),
                DataRow(
                  cells: [
                    const DataCell(
                      Text(
                        'Name',
                        style: TextStyle(
                          color: Color(0x99E6EDF3),
                        ),
                      ),
                    ),
                    for (final d in items)
                      DataCell(
                        Text(d.label),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.hintText,
  }) : super(key: key);

  final String label;
  final TextEditingController controller;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xB3E6EDF3),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 13),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0x66E6EDF3),
              fontSize: 12,
            ),
            filled: true,
            fillColor: const Color(0xFF0B0F14),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0x26FFFFFF),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0x26FFFFFF),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xB3E6EDF3),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF0B0F14),
          style: const TextStyle(
            color: Color(0xFFE6EDF3),
            fontSize: 13,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0B0F14),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0x26FFFFFF),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0x26FFFFFF),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
              ),
            ),
          ),
          items: items,
        ),
      ],
    );
  }
}

class _DriverSeries {
  final String label;
  final Color color;
  final List<FlSpot> points;

  const _DriverSeries({
    required this.label,
    required this.color,
    required this.points,
  });
}
