import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

import '../models/lap.dart';

class LapsListPage extends StatefulWidget {
  final int? initialDriverNumber;

  const LapsListPage({super.key, this.initialDriverNumber});

  @override
  State<LapsListPage> createState() => _LapsListPageState();
}

class _LapsListPageState extends State<LapsListPage> {
  static const _baseUrl = 'http://127.0.0.1:8000';

  final _sessionKeyController = TextEditingController();
  final _driverNumberController = TextEditingController();
  final _lapNumberController = TextEditingController();
  final _meetingKeyController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<Lap> _laps = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialDriverNumber != null) {
      _driverNumberController.text = widget.initialDriverNumber.toString();
    }
  }

  @override
  void dispose() {
    _sessionKeyController.dispose();
    _driverNumberController.dispose();
    _lapNumberController.dispose();
    _meetingKeyController.dispose();
    super.dispose();
  }

  String _buildUrl() {
    final params = <String, String>{};

    void add(String key, TextEditingController c) {
      final v = c.text.trim();
      if (v.isNotEmpty) params[key] = v;
    }

    add('session_key', _sessionKeyController);
    add('driver_number', _driverNumberController);
    add('lap_number', _lapNumberController);
    add('meeting_key', _meetingKeyController);

    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    return qs.isEmpty ? '$_baseUrl/laps/api/' : '$_baseUrl/laps/api/?$qs';
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final request = context.read<CookieRequest>();

    try {
      final url = _buildUrl();
      final response = await request.get(url) as Map<String, dynamic>;
      if (response['ok'] != true) {
        throw Exception(response['error'] ?? 'Failed to load laps');
      }
      final List<dynamic> data = response['data'] ?? [];
      final laps = data.map((e) => Lap.fromJson(e)).toList();

      setState(() {
        _laps = laps;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clear() {
    _sessionKeyController.clear();
    _driverNumberController.clear();
    _lapNumberController.clear();
    _meetingKeyController.clear();
    setState(() {
      _laps = [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      drawer: const SpeedViewDrawer(currentRoute: AppRoutes.laps),
      appBar: const SpeedViewAppBar(title: 'Laps'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackRow(context),
            const SizedBox(height: 18),
            _buildMetric(),
            const SizedBox(height: 16),

            // filter form
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1117), Color(0xFF111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white24.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildField(_sessionKeyController, 'session_key'),
                      _buildField(_driverNumberController, 'driver_number'),
                      _buildField(_lapNumberController, 'lap_number'),
                      _buildField(_meetingKeyController, 'meeting_key'),
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _load,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Load'),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _clear,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side:
                                const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error != null ? _error! : '${_laps.length} item(s)',
                style: TextStyle(
                  color: _error != null ? Colors.red[300] : Colors.white60,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _laps.isEmpty
                  ? const Center(
                      child: Text(
                        'No data.',
                        style: TextStyle(color: Color(0xFFE6EDF3)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _laps.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: Colors.white24,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final lap = _laps[index];
                        return _buildLapRow(lap);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackRow(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () =>
          Navigator.of(context).pushReplacementNamed(AppRoutes.home),
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

  Widget _buildMetric() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2933), Color(0xFF111827)],
        ),
        border: Border.all(color: Colors.white24.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timeline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Text(
            '${_laps.length} laps loaded',
            style: const TextStyle(
              color: Color(0xFFE6EDF3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: c,
        style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF0D1117),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLapRow(Lap lap) {
    String _sec(double? v) => v == null ? '—' : v.toStringAsFixed(3);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lap.dateStartStr ?? '—',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${lap.driverNumber ?? '-'}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lap ${lap.lapNumber ?? '-'}',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Text(
                _sec(lap.lapDuration),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'S1 ${_sec(lap.sector1)}  ·  S2 ${_sec(lap.sector2)}  ·  S3 ${_sec(lap.sector3)}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          Text(
            'i1 ${_sec(lap.i1Speed)}  ·  i2 ${_sec(lap.i2Speed)}  ·  ST ${_sec(lap.stSpeed)}'
            '  ·  Pit out: ${lap.isPitOutLap ? 'Yes' : 'No'}',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
