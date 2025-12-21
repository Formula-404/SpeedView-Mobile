import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

import '../models/pit_stop.dart';

class PitListPage extends StatefulWidget {
  final int? initialDriverNumber;

  const PitListPage({super.key, this.initialDriverNumber});

  @override
  State<PitListPage> createState() => _PitListPageState();
}

class _PitListPageState extends State<PitListPage> {
  static const String _baseUrl = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id';
  static const int _pageSize = 20;

  final _sessionKeyController = TextEditingController();
  final _driverNumberController = TextEditingController();
  final _lapNumberController = TextEditingController();
  final _meetingKeyController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  static const double _scrollThresholdPx = 320;

  final List<PitStop> _pits = [];

  bool _isInitialLoading = false;
  bool _isMoreLoading = false;
  bool _hasMore = true;

  int _offset = 0;
  int _totalCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    if (widget.initialDriverNumber != null) {
      _driverNumberController.text = widget.initialDriverNumber.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPage(reset: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    _sessionKeyController.dispose();
    _driverNumberController.dispose();
    _lapNumberController.dispose();
    _meetingKeyController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_isInitialLoading || _isMoreLoading) return;
    if (!_hasMore) return;

    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _scrollThresholdPx) {
      _loadPage(reset: false);
    }
  }

  Map<String, String> _buildFilters() {
    final Map<String, String> params = {};

    void add(String key, TextEditingController c) {
      final v = c.text.trim();
      if (v.isNotEmpty) params[key] = v;
    }

    add('session_key', _sessionKeyController);
    add('driver_number', _driverNumberController);
    add('lap_number', _lapNumberController);
    add('meeting_key', _meetingKeyController);

    return params;
  }

  Future<void> _loadPage({required bool reset}) async {
    // guard: cegah double request
    if (_isInitialLoading || _isMoreLoading) return;
    if (!reset && !_hasMore) return;

    final request = context.read<CookieRequest>();

    if (reset) {
      setState(() {
        _error = null;
        _isInitialLoading = true;

        _pits.clear();
        _offset = 0;
        _totalCount = 0;
        _hasMore = true;
      });
    } else {
      setState(() {
        _error = null;
        _isMoreLoading = true;
      });
    }

    try {
      final filters = _buildFilters();
      final params = <String, String>{
        ...filters,
        'limit': _pageSize.toString(),
        'offset': _offset.toString(),
      };

      final qs = params.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final url = '$_baseUrl/pit/api/?$qs';

      final raw = await request.get(url);

      if (raw is! Map) {
        throw Exception('Invalid response from server (not a JSON object)');
      }
      final Map<String, dynamic> response = Map<String, dynamic>.from(raw);

      if (response['ok'] != true) {
        throw Exception(response['error'] ?? 'Failed to load pit data');
      }

      final dynamic dataRaw = response['data'];
      final List<dynamic> rawData = (dataRaw is List) ? dataRaw : <dynamic>[];

      final List<PitStop> newPits = rawData.map((e) {
        if (e is Map) return PitStop.fromJson(Map<String, dynamic>.from(e));
        throw Exception('Invalid pit item');
      }).toList();

      if (!mounted) return;
      setState(() {
        // count bisa int atau string
        final dynamic c = response['count'];
        if (c != null) {
          _totalCount = c is int ? c : int.tryParse(c.toString()) ?? _totalCount;
        }

        // append data
        _pits.addAll(newPits);

        // next_offset bisa int/string/null
        final dynamic nextOffsetRaw = response['next_offset'];
        if (nextOffsetRaw != null) {
          _offset = nextOffsetRaw is int
              ? nextOffsetRaw
              : int.tryParse(nextOffsetRaw.toString()) ?? (_offset + newPits.length);
        } else {
          _offset += newPits.length;
        }

        final bool serverHasMore = response['has_more'] == true;
        // safety: kalau server bilang has_more tapi page kosong, stop supaya tidak loop
        _hasMore = serverHasMore && newPits.isNotEmpty;
      });

      // Jika item sedikit dan belum bisa scroll, prefetch 1 halaman lagi (opsional tapi membantu “stuck loading”)
      _maybePrefetchIfNotScrollable();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _hasMore = false;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
        _isMoreLoading = false;
      });
    }
  }

  void _maybePrefetchIfNotScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      if (_isInitialLoading || _isMoreLoading) return;
      if (!_hasMore) return;

      // kalau maxScrollExtent == 0 artinya list belum cukup panjang untuk discroll
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) {
        _loadPage(reset: false);
      }
    });
  }

  void _clear() {
    _sessionKeyController.clear();
    _driverNumberController.clear();
    _lapNumberController.clear();
    _meetingKeyController.clear();

    setState(() {
      _pits.clear();
      _error = null;
      _offset = 0;
      _totalCount = 0;
      _hasMore = true;
      _isInitialLoading = false;
      _isMoreLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadPage(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      drawer: const SpeedViewDrawer(currentRoute: AppRoutes.pitStops),
      appBar: const SpeedViewAppBar(title: 'Pit Stops'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackRow(context),
              const SizedBox(height: 18),
              _buildMetric(),
              const SizedBox(height: 16),
              _buildFilterCard(),
              const SizedBox(height: 12),
              _buildMetaText(),
              const SizedBox(height: 8),
              Expanded(
                child: _isInitialLoading && _pits.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.red))
                    : _pits.isEmpty && _error == null
                        ? const Center(
                            child: Text(
                              'No data. Tekan Load untuk memuat data.',
                              style: TextStyle(color: Color(0xFFE6EDF3)),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _buildListView(),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildMetric() {
    final loaded = _pits.length;
    final total = _totalCount;

    String text;
    if (total > 0) {
      text = '$loaded / $total pit stops loaded';
    } else {
      text = '$loaded pit stops loaded';
    }

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
          const Icon(Icons.ev_station_outlined, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
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
                  onPressed: _isInitialLoading ? null : () => _loadPage(reset: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isInitialLoading
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
                  onPressed: _isInitialLoading ? null : _clear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaText() {
    if (_error != null) {
      return Text(
        _error!,
        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
      );
    }

    if (_totalCount > 0) {
      final hint = _hasMore ? 'Scroll ke bawah untuk memuat 20 data berikutnya.' : 'Semua data sudah dimuat.';
      return Text(
        '${_pits.length} dari $_totalCount item(s). $hint',
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      );
    }

    return Text(
      '${_pits.length} item(s).',
      style: const TextStyle(color: Colors.white60, fontSize: 12),
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
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _pits.length + 1, // +1 untuk footer (loader / end / error)
      itemBuilder: (context, index) {
        if (index == _pits.length) {
          if (_error != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Stopped: $_error',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!_hasMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No more data.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: _isMoreLoading
                  ? const CircularProgressIndicator(color: Colors.redAccent)
                  : const Text(
                      'Scroll to load more…',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
            ),
          );
        }

        final pit = _pits[index];
        return Column(
          children: [
            _buildPitRow(pit),
            const Divider(color: Colors.white24, height: 1),
          ],
        );
      },
    );
  }

  Widget _buildPitRow(PitStop pit) {
    String sec(double? v) => v == null ? '—' : '${v.toStringAsFixed(3)} s';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pit.dateStr ?? '—',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${pit.driverNumber ?? '-'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lap ${pit.lapNumber ?? '-'}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Text(
                sec(pit.pitDuration),
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
