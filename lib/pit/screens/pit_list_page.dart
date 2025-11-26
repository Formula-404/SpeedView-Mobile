import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/pit_stop.dart';

class PitListPage extends StatefulWidget {
  final int? initialDriverNumber;

  const PitListPage({super.key, this.initialDriverNumber});

  @override
  State<PitListPage> createState() => _PitListPageState();
}

class _PitListPageState extends State<PitListPage> {
  static const _baseUrl = 'http://127.0.0.1:8000';

  final _sessionKeyController = TextEditingController();
  final _driverNumberController = TextEditingController();
  final _lapNumberController = TextEditingController();
  final _meetingKeyController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<PitStop> _pits = [];

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

    return qs.isEmpty ? '$_baseUrl/pit/api/' : '$_baseUrl/pit/api/?$qs';
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
        throw Exception(response['error'] ?? 'Failed to load pit data');
      }
      final List<dynamic> data = response['data'] ?? [];
      final pits = data.map((e) => PitStop.fromJson(e)).toList();

      setState(() {
        _pits = pits;
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
      _pits = [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      appBar: AppBar(
        title: const Text(
          'Pit Stops',
          style: TextStyle(color: Color(0xFFE6EDF3)),
        ),
        backgroundColor: const Color(0xFF161B22),
        iconTheme: const IconThemeData(color: Color(0xFFE6EDF3)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error != null
                    ? _error!
                    : '${_pits.length} item(s)',
                style: TextStyle(
                  color: _error != null ? Colors.red[300] : Colors.white60,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _pits.isEmpty
                  ? const Center(
                      child: Text(
                        'No data.',
                        style: TextStyle(color: Color(0xFFE6EDF3)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _pits.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: Colors.white24,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final pit = _pits[index];
                        return _buildPitRow(pit);
                      },
                    ),
            ),
          ],
        ),
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
        ),
      ),
    );
  }

  Widget _buildPitRow(PitStop pit) {
    String _sec(double? v) =>
        v == null ? '—' : '${v.toStringAsFixed(3)} s';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pit.dateStr ?? '—',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '#${pit.driverNumber ?? '-'}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Lap ${pit.lapNumber ?? '-'}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Text(
                _sec(pit.pitDuration),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Session ${pit.sessionKey ?? '-'}  ·  Meeting ${pit.meetingKey ?? '-'}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
