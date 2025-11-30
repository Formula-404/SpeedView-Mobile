// Placeholder File
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/common/navigation/app_routes.dart'; 
import 'package:speedview/common/widgets/speedview_app_bar.dart'; 
import 'package:speedview/common/widgets/speedview_drawer.dart'; 
import '../models/team_model.dart';
import '../widgets/team_card.dart';
// import 'team_detail_screen.dart'; // TODO
// import 'team_form_screen.dart';   // TODO

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Team> _allTeams = [];
  List<Team> _filteredTeams = [];
  bool _isLoading = true;

  final Color _backgroundColor = const Color(0xFF05070B);
  final Color _cardColor = const Color(0xFF0F151F);
  final Color _accentRed = const Color(0xFFFB4D46);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTeams();
    });
  }

  Future<void> _fetchTeams() async {
    final request = context.read<CookieRequest>();
    const String url = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id/team/api/';
    
    try {
      final response = await request.get(url);
      
      if (response['ok'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        final teams = data.map((json) => Team.fromJson(json)).toList();

        setState(() {
          _allTeams = teams;
          _filteredTeams = teams;
          _isLoading = false;
        });
        
        if (_searchController.text.isNotEmpty) {
          _filterTeams(_searchController.text);
        }
      }
    } catch (e) {
      debugPrint('Error fetching teams: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterTeams(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTeams = _allTeams;
      } else {
        final q = query.toLowerCase();
        _filteredTeams = _allTeams.where((t) {
          return t.teamName.toLowerCase().contains(q) ||
                 t.shortCode.toLowerCase().contains(q) ||
                 t.country.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _deleteTeam(String teamName) async {
    final request = context.read<CookieRequest>();
    final encodedName = Uri.encodeComponent(teamName);
    final url = 'http://127.0.0.1:8000/team/api/delete/$encodedName/';
    
    try {
      final response = await request.post(url, {});
      if (response['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Team deleted successfully"), 
            backgroundColor: Colors.green
          ),
        );
        _fetchTeams(); 
      } else {
        throw Exception(response['error'] ?? "Unknown error");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete: $e"), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  void _showDeleteConfirmation(Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Team', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${team.teamName}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTeam(team.teamName); 
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const SpeedViewAppBar(title: 'Teams'),
      drawer: const SpeedViewDrawer(currentRoute: AppRoutes.teams), 
      
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: _accentRed,
              onPressed: () async {
                /*
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TeamFormScreen()),
                );
                if (result == true) _fetchTeams();
                */
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
          
      body: RefreshIndicator(
        color: _accentRed,
        backgroundColor: _cardColor,
        onRefresh: _fetchTeams,
        child: SafeArea(
          child: Column(
            children: [
              // --- Header Section ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumbs
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                          child: Text(
                            'Home',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6), 
                              fontWeight: FontWeight.w500,
                              fontSize: 14
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.chevron_right, size: 16, color: Colors.white.withOpacity(0.6)),
                        ),
                        const Text(
                          'Team',
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 14
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Title
                    const Text(
                      'TEAMS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontFamily: 'Alphacorsa',
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: _filterTeams,
                        decoration: InputDecoration(
                          hintText: 'Search team...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.4)),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterTeams('');
                                },
                              ) 
                            : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Results Info & Meta ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isLoading 
                        ? "Loading..." 
                        : "${_filteredTeams.length} teams found",
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    ),
                    if (!_isLoading)
                      Row(
                        children: [
                           _buildLegendDot("Primary", Colors.white),
                           const SizedBox(width: 8),
                           _buildLegendDot("Secondary", Colors.white.withOpacity(0.5)),
                        ],
                      )
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // --- List Content ---
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: _accentRed))
                    : _filteredTeams.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text(
                                  'No teams match your search.', 
                                  style: TextStyle(color: Colors.white.withOpacity(0.5))
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: _filteredTeams.length,
                            itemBuilder: (context, index) {
                              final team = _filteredTeams[index];
                              return TeamCard(
                                team: team,
                                isAdmin: _isAdmin,
                                onTap: () {
                                  /*
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeamDetailScreen(team: team),
                                    ),
                                  );
                                  */
                                },
                                onEdit: () {
                                },
                                onDelete: () => _showDeleteConfirmation(team),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
      ],
    );
  }
}