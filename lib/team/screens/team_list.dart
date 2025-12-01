import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/Team.dart';
import '../widgets/team_card.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Team> _allTeams = [];
  List<Team> _filteredTeams = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.get(Uri.parse("http://127.0.0.1:8000/team/api/"));

      if (res.statusCode != 200) {
        throw Exception('Status ${res.statusCode}: ${res.reasonPhrase}');
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['ok'] != true) {
        throw Exception(body['error'] ?? 'Failed to load teams');
      }

      final List<dynamic> data = body['data'] ?? [];
      final teams = data
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _allTeams = teams;
        _filteredTeams = List<Team>.from(teams);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _allTeams = [];
        _filteredTeams = [];
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _filteredTeams = List<Team>.from(_allTeams);
      });
      return;
    }

    setState(() {
      _filteredTeams = _allTeams.where((t) {
        return t.teamName.toLowerCase().contains(q) ||
            t.shortCode.toLowerCase().contains(q);
      }).toList();
    });
  }

  String _resultsInfo() {
    if (_loading) return 'Loading teams…';
    final total = _allTeams.length;
    final filtered = _filteredTeams.length;
    if (total == 0) return '0 teams';
    if (filtered == total) {
      return '$total team${total == 1 ? '' : 's'}';
    }
    return '$filtered / $total teams';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTeams,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header + search + meta row (unchanged from previous answer)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Home',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0x99FFFFFF),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '›',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0x99FFFFFF),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Team',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Teams',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1117),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(color: Colors.white),
                                    cursorColor: const Color(0xFFEF4444),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      hintText: 'Search team...',
                                      hintStyle: TextStyle(
                                        color:
                                            Colors.white.withOpacity(0.4),
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      suffixIcon: Icon(
                                        Icons.search,
                                        color:
                                            Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _resultsInfo(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0x99FFFFFF),
                                ),
                              ),
                              Row(
                                children: [
                                  _metaChip('Primary color'),
                                  const SizedBox(width: 8),
                                  _metaChip('Secondary color'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Content states
                  if (_loading)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.red.shade500,
                          ),
                        ),
                      ),
                    )
                  else if (_error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          child: Text(
                            'Failed to load teams.\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (_filteredTeams.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Text(
                            'No teams match your search.',
                            style: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              constraints.maxWidth > 600 ? 3 : 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final team = _filteredTeams[index];
                            return TeamCard(
                              team: team,
                              onTap: () {
                                // later: navigate to team_detail
                              },
                            );
                          },
                          childCount: _filteredTeams.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xB3FFFFFF),
        ),
      ),
    );
  }
}
