import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import '../models/session_model.dart';
import '../widgets/session_meeting_card.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<MeetingData> _meetings = [];
  PaginationData? _pagination;
  bool _isLoading = true;
  String _errorMessage = '';
  
  int _currentPage = 1;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSessions();
    });
  }

  Future<void> _fetchSessions({int page = 1, String query = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final request = context.read<CookieRequest>();
    String baseUrl = 'http://127.0.0.1:8000'; 
    String endpoint = '$baseUrl/session/api/?page=$page&q=$query';

    try {
      final response = await request.get(endpoint);
      final sessionResponse = SessionResponse.fromJson(response);

      if (sessionResponse.ok) {
        setState(() {
          _meetings = sessionResponse.data;
          _pagination = sessionResponse.pagination;
          _currentPage = page;
          _currentQuery = query;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = sessionResponse.error ?? "Unknown error";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF05070B);
    const cardColor = Color(0xFF0F151F);
    const primaryRed = Color(0xFFFB4D46);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const SpeedViewAppBar(title: 'Sessions'),
      drawer: const SpeedViewDrawer(currentRoute: AppRoutes.sessions),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Back
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.home);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: .1)),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      
                      const SizedBox(width: 12),

                      // Search Bar
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: .1)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search session...',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: .3)),
                              prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: .4)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onSubmitted: (value) => _fetchSessions(page: 1, query: value),
                          ),
                        ),
                      ),
                    ],
                  ),                  
                  const SizedBox(height: 16),

                  // Pagination Bar
                  if (!_isLoading && _pagination != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12), // Rounded ujung
                        border: Border.all(color: Colors.white.withValues(alpha: .1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Page ${_pagination!.currentPage} of ${_pagination!.totalPages} • ${_pagination!.totalMeetings} meetings',
                            style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 13),
                          ),
                          Row(
                            children: [
                              _buildPaginationButton(
                                label: 'Prev',
                                icon: Icons.chevron_left,
                                isEnabled: _pagination!.hasPrevious,
                                onTap: () => _fetchSessions(page: _currentPage - 1, query: _currentQuery),
                              ),
                              const SizedBox(width: 8),
                              _buildPaginationButton(
                                label: 'Next',
                                icon: Icons.chevron_right,
                                isRightIcon: true,
                                isEnabled: _pagination!.hasNext,
                                onTap: () => _fetchSessions(page: _currentPage + 1, query: _currentQuery),
                                isPrimary: true,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryRed))
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                      : _meetings.isEmpty
                          ? Center(child: Text('No sessions found.', style: TextStyle(color: Colors.white.withValues(alpha: .5))))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                              itemCount: _meetings.length,
                              itemBuilder: (context, index) {
                                return SessionMeetingCard(data: _meetings[index]);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationButton({
    required String label,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
    bool isRightIcon = false,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled 
              ? (isPrimary ? const Color(0xFFFB4D46) : Colors.white.withValues(alpha: .1)) 
              : Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (!isRightIcon) Icon(icon, size: 16, color: isEnabled ? Colors.white : Colors.white38),
            if (!isRightIcon) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white38,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (isRightIcon) const SizedBox(width: 4),
            if (isRightIcon) Icon(icon, size: 16, color: isEnabled ? Colors.white : Colors.white38),
          ],
        ),
      ),
    );
  }
}