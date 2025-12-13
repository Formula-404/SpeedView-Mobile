import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:speedview/user/constants.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/theme/typography.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

import 'package:speedview/driver/screens/driver_list_page.dart';
import 'package:speedview/laps/screens/laps_list_page.dart';
import 'package:speedview/pit/screens/pit_list_page.dart';
import 'package:speedview/user/screens/login.dart';
import 'package:speedview/user/screens/profile.dart';

import 'package:speedview/comparison/models/Comparison.dart';
import 'package:speedview/comparison/models/ComparisonDetail.dart';
import 'package:speedview/comparison/screens/comparison_list_screen.dart';
import 'package:speedview/comparison/screens/comparison_team_detail_screen.dart';
import 'package:speedview/comparison/screens/comparison_driver_detail_screen.dart';
import 'package:speedview/comparison/screens/comparison_circuit_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = 'User';
  String _role = 'User';
  static const String _apiBaseUrl = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id';

  List<Map<String, dynamic>> _meetings = [];
  int? _selectedMeetingKey;
  Map<String, dynamic>? _meetingData;
  bool _loadingMeetings = true;
  bool _loadingDashboard = false;

  Comparison? _latestComparison;
  List<ComparisonTeamItem>? _comparisonTeams;
  List<ComparisonCircuitItem>? _comparisonCircuits;
  bool _loadingComparison = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchMeetings();
    _fetchLatestComparison();
  }

  Future<void> _fetchProfile() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get(buildSpeedViewUrl('/profile-flutter/'));
      if (response['status'] == true && mounted) {
        setState(() {
          _username = response['username'] as String;
          _role = response['role'] as String;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchMeetings() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('$_apiBaseUrl/api/recent-meetings/');
      if (response['ok'] == true && mounted) {
        final data = List<Map<String, dynamic>>.from(response['data'] ?? []);
        setState(() {
          _meetings = data;
          _loadingMeetings = false;
          if (data.isNotEmpty) {
            _selectedMeetingKey = data[0]['meeting_key'] as int?;
            _fetchDashboardData(_selectedMeetingKey!);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMeetings = false);
    }
  }

  Future<void> _fetchDashboardData(int meetingKey) async {
    setState(() => _loadingDashboard = true);
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('$_apiBaseUrl/api/dashboard-data/?meeting_key=$meetingKey');
      if (response['ok'] == true && mounted) {
        setState(() {
          _meetingData = Map<String, dynamic>.from(response['data'] ?? {});
          _loadingDashboard = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDashboard = false);
    }
  }

  Future<void> _fetchLatestComparison() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('$_apiBaseUrl/comparison/api/list/?scope=all');
      if (response['ok'] == true && mounted) {
        final comparisons = Comparison.listFromJson(response['data']);
        if (comparisons.isNotEmpty) {
          final latest = comparisons.first;
          setState(() {
            _latestComparison = latest;
          });
          await _fetchComparisonDetail(latest);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComparison = false);
    }
  }

  Future<void> _fetchComparisonDetail(Comparison comparison) async {
    final request = context.read<CookieRequest>();
    try {
      final url = '$_apiBaseUrl/comparison/api/${comparison.id}/';
      final body = await request.get(url);
      if (mounted && body['ok'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final items = data['items'] as List<dynamic>? ?? [];
        if (comparison.module == 'team') {
          setState(() {
            _comparisonTeams = items.map((e) => ComparisonTeamItem.fromJson(e as Map<String, dynamic>)).toList();
            _loadingComparison = false;
          });
        } else if (comparison.module == 'circuit') {
          setState(() {
            _comparisonCircuits = items.map((e) => ComparisonCircuitItem.fromJson(e as Map<String, dynamic>)).toList();
            _loadingComparison = false;
          });
        } else {
          setState(() => _loadingComparison = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComparison = false);
    }
  }

  Future<void> _logout() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(buildSpeedViewUrl('/logout-flutter/'), {});
      if (!mounted) return;
      if (response['status'] == true) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SpeedViewDrawer(currentRoute: AppRoutes.home),
      appBar: SpeedViewAppBar(
        title: 'SpeedView Home',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            offset: const Offset(0, 50),
            color: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white24),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _role == 'admin' ? Colors.red.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_role.toUpperCase(), style: TextStyle(color: _role == 'admin' ? Colors.red[400] : Colors.blue[400], fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white24),
                  ],
                ),
              ),
              const PopupMenuItem<String>(value: 'profile', child: Row(children: [Icon(Icons.person, color: Colors.white70, size: 20), SizedBox(width: 12), Text('Profile', style: TextStyle(color: Colors.white))])),
              const PopupMenuItem<String>(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red, size: 20), SizedBox(width: 12), Text('Log Out', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroCard(context),
          const SizedBox(height: 20),
          _buildMeetingSelector(),
          const SizedBox(height: 20),
          if (_loadingDashboard)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_meetingData != null) ...[
            _buildMeetingInfo(),
            const SizedBox(height: 20),
            _buildDriversWidget(),
            const SizedBox(height: 20),
            _buildWeatherWidget(),
            const SizedBox(height: 20),
          ],
          _buildComparisonStatsWidget(),
          const SizedBox(height: 20),
          _buildModulesGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFB4D46), Color(0xFFFF7A5A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: .3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SpeedView Mobile', style: speedViewHeadingStyle(context, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('Your Formula 1 data dashboard on the go.', style: TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMeetingSelector() {
    if (_loadingMeetings) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF0F151E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .08))),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F151E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Meeting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _meetings.map((m) {
                final key = m['meeting_key'] as int?;
                final isSelected = key == _selectedMeetingKey;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (key != null) {
                        setState(() => _selectedMeetingKey = key);
                        _fetchDashboardData(key);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEF4444) : Colors.grey.shade800.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${m['meeting_name']} ${m['year']}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.white70),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingInfo() {
    final meeting = _meetingData?['meeting'] as Map<String, dynamic>? ?? {};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F151E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((meeting['meeting_name'] ?? '').toString().toUpperCase(), style: speedViewHeadingStyle(context, fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _infoChip(Icons.flag, meeting['country_name']?.toString() ?? ''),
              _infoChip(Icons.calendar_today, meeting['year']?.toString() ?? ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.white70)),
      ],
    );
  }

  Widget _buildDriversWidget() {
    final drivers = List<Map<String, dynamic>>.from(_meetingData?['drivers'] ?? []);
    if (drivers.isEmpty) return const SizedBox.shrink();
    final displayDrivers = drivers.take(9).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F151E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Drivers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverListPage())),
                child: const Text('View All', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.9),
            itemCount: displayDrivers.length,
            itemBuilder: (_, i) {
              final d = displayDrivers[i];
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: .08))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: (d['headshot_url']?.toString().isNotEmpty == true) ? NetworkImage(d['headshot_url'].toString()) : null,
                      child: (d['headshot_url']?.toString().isEmpty ?? true) ? const Icon(Icons.person, size: 20, color: Colors.white54) : null,
                    ),
                    const SizedBox(height: 6),
                    Text(d['broadcast_name']?.toString() ?? d['full_name']?.toString() ?? '', textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text('#${d['driver_number']}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    final weather = List<Map<String, dynamic>>.from(_meetingData?['weather'] ?? []);
    if (weather.isEmpty) return const SizedBox.shrink();
    final latest = weather.last;
    final airTemp = latest['air_temperature'];
    final trackTemp = latest['track_temperature'];
    final humidity = latest['humidity'];
    final rainfall = latest['rainfall'] == true ? 'Yes' : 'No';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F151E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weather', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _weatherCard('Air Temp', '${airTemp ?? '--'}°C', Icons.thermostat, const Color(0xFF3B82F6))),
              const SizedBox(width: 8),
              Expanded(child: _weatherCard('Track Temp', '${trackTemp ?? '--'}°C', Icons.local_fire_department, const Color(0xFFF97316))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _weatherCard('Humidity', '${humidity ?? '--'}%', Icons.water_drop, const Color(0xFF22C55E))),
              const SizedBox(width: 8),
              Expanded(child: _weatherCard('Rainfall', rainfall, Icons.umbrella, const Color(0xFF8B5CF6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: .3))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 10, color: color.withValues(alpha: .8))),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonStatsWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F151E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Comparison Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComparisonListScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(16)),
                  child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingComparison)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_latestComparison == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .03), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('No comparisons yet', style: TextStyle(color: Colors.white54))),
            )
          else ...[
            Text(_latestComparison!.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 4),
            Text('${_latestComparison!.moduleLabel} • ${_latestComparison!.items.length} items', style: const TextStyle(fontSize: 13, color: Colors.white54)),
            const SizedBox(height: 16),
            if (_comparisonTeams != null && _comparisonTeams!.isNotEmpty)
              _buildTeamRadarChart()
            else if (_comparisonCircuits != null && _comparisonCircuits!.isNotEmpty)
              _buildCircuitRadarChart()
            else
              _buildSimpleStatBars(),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () {
                  if (_latestComparison == null) return;
                  switch (_latestComparison!.module) {
                    case 'team':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ComparisonTeamDetailScreen(comparison: _latestComparison!, apiBaseUrl: _apiBaseUrl)));
                      break;
                    case 'circuit':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ComparisonCircuitDetailScreen(comparison: _latestComparison!, apiBaseUrl: _apiBaseUrl)));
                      break;
                    case 'driver':
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ComparisonDriverDetailScreen(comparison: _latestComparison!, apiBaseUrl: _apiBaseUrl)));
                      break;
                  }
                },
                child: const Text('Tap to view details →', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamRadarChart() {
    final teams = _comparisonTeams!.take(4).toList();
    final colors = [const Color(0xFFEF4444), const Color(0xFF3B82F6), const Color(0xFF22C55E), const Color(0xFFF97316)];
    
    double maxPoints = 0;
    double maxWins = 0;
    double maxPodiums = 0;
    for (final t in teams) {
      if ((t.points ?? 0) > maxPoints) maxPoints = t.points ?? 0;
      if ((t.raceVictories ?? 0) > maxWins) maxWins = (t.raceVictories ?? 0).toDouble();
      if ((t.podiums ?? 0) > maxPodiums) maxPodiums = (t.podiums ?? 0).toDouble();
    }
    if (maxPoints == 0) maxPoints = 1;
    if (maxWins == 0) maxWins = 1;
    if (maxPodiums == 0) maxPodiums = 1;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 3,
              tickBorderData: BorderSide(color: Colors.white.withValues(alpha: .1)),
              gridBorderData: BorderSide(color: Colors.white.withValues(alpha: .1)),
              radarBorderData: BorderSide(color: Colors.white.withValues(alpha: .2)),
              titleTextStyle: const TextStyle(fontSize: 10, color: Colors.white70),
              getTitle: (index, _) {
                switch (index) {
                  case 0: return RadarChartTitle(text: 'Points');
                  case 1: return RadarChartTitle(text: 'Wins');
                  case 2: return RadarChartTitle(text: 'Podiums');
                  default: return const RadarChartTitle(text: '');
                }
              },
              dataSets: teams.asMap().entries.map((e) {
                final t = e.value;
                final c = colors[e.key % colors.length];
                return RadarDataSet(
                  fillColor: c.withValues(alpha: .2),
                  borderColor: c,
                  borderWidth: 2,
                  entryRadius: 3,
                  dataEntries: [
                    RadarEntry(value: ((t.points ?? 0) / maxPoints) * 100),
                    RadarEntry(value: ((t.raceVictories ?? 0) / maxWins) * 100),
                    RadarEntry(value: ((t.podiums ?? 0) / maxPodiums) * 100),
                  ],
                );
              }).toList(),
              ticksTextStyle: const TextStyle(fontSize: 8, color: Colors.white38),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: teams.asMap().entries.map((e) {
            final t = e.value;
            final c = colors[e.key % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(t.shortCode.isNotEmpty ? t.shortCode : t.teamName, style: const TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCircuitRadarChart() {
    final circuits = _comparisonCircuits!.take(4).toList();
    final colors = [const Color(0xFFEF4444), const Color(0xFF3B82F6), const Color(0xFF22C55E), const Color(0xFFF97316)];
    
    double maxLength = 0;
    double maxTurns = 0;
    double maxGP = 0;
    for (final c in circuits) {
      if ((c.lengthKm ?? 0) > maxLength) maxLength = c.lengthKm ?? 0;
      if ((c.turns ?? 0) > maxTurns) maxTurns = (c.turns ?? 0).toDouble();
      if ((c.grandsPrixHeld ?? 0) > maxGP) maxGP = (c.grandsPrixHeld ?? 0).toDouble();
    }
    if (maxLength == 0) maxLength = 1;
    if (maxTurns == 0) maxTurns = 1;
    if (maxGP == 0) maxGP = 1;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 3,
              tickBorderData: BorderSide(color: Colors.white.withValues(alpha: .1)),
              gridBorderData: BorderSide(color: Colors.white.withValues(alpha: .1)),
              radarBorderData: BorderSide(color: Colors.white.withValues(alpha: .2)),
              titleTextStyle: const TextStyle(fontSize: 10, color: Colors.white70),
              getTitle: (index, _) {
                switch (index) {
                  case 0: return RadarChartTitle(text: 'Length (km)');
                  case 1: return RadarChartTitle(text: 'Turns');
                  case 2: return RadarChartTitle(text: 'GPs Held');
                  default: return const RadarChartTitle(text: '');
                }
              },
              dataSets: circuits.asMap().entries.map((e) {
                final c = e.value;
                final col = colors[e.key % colors.length];
                return RadarDataSet(
                  fillColor: col.withValues(alpha: .2),
                  borderColor: col,
                  borderWidth: 2,
                  entryRadius: 3,
                  dataEntries: [
                    RadarEntry(value: ((c.lengthKm ?? 0) / maxLength) * 100),
                    RadarEntry(value: ((c.turns ?? 0) / maxTurns) * 100),
                    RadarEntry(value: ((c.grandsPrixHeld ?? 0) / maxGP) * 100),
                  ],
                );
              }).toList(),
              ticksTextStyle: const TextStyle(fontSize: 8, color: Colors.white38),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: circuits.asMap().entries.map((e) {
            final c = e.value;
            final col = colors[e.key % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(c.label.length > 15 ? '${c.label.substring(0, 15)}...' : c.label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSimpleStatBars() {
    final items = _latestComparison?.items ?? [];
    final colors = [const Color(0xFFEF4444), const Color(0xFF3B82F6), const Color(0xFF22C55E), const Color(0xFFF97316)];
    return Row(
      children: List.generate(
        items.length > 4 ? 4 : items.length,
        (i) => Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
    );
  }

  Widget _buildModulesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Explore Modules', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppRoutes.destinations.where((d) => d.route != AppRoutes.home).map((d) {
            return GestureDetector(
              onTap: () {
                if (d.title == 'Drivers') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverListPage()));
                } else if (d.title == 'Laps') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LapsListPage()));
                } else if (d.title == 'Pit Stops' || d.title == 'Pit') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PitListPage()));
                } else if (d.title == 'Profile') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                } else {
                  Navigator.of(context).pushReplacementNamed(d.route);
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width / 2 - 26,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: .08)),
                  color: const Color(0xFF0F151E),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(d.icon, color: Colors.white70, size: 22),
                    const SizedBox(height: 10),
                    Text(d.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(d.description ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
