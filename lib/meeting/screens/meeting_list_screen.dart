import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/theme/typography.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

import '../meeting_service.dart';
import '../models/meeting.dart';
import '../widgets/dart.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key, this.service});

  final MeetingService? service;

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  late final MeetingService _service;
  late final bool _ownsService;
  final TextEditingController _searchController = TextEditingController();
  final List<Meeting> _meetings = [];
  MeetingPagination? _pagination;
  bool _isLoading = true;
  String? _errorMessage;
  String _currentQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MeetingService();
    _ownsService = widget.service == null;
    _searchController.addListener(() => setState(() {}));
    _fetchMeetings();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    if (_ownsService) {
      _service.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchMeetings({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await _service.fetchMeetings(query: _currentQuery, page: page);
      setState(() {
        _meetings
          ..clear()
          ..addAll(response.meetings);
        _pagination = response.pagination;
        _isLoading = false;
      });
    } on MeetingException catch (e) {
      setState(() {
        _meetings.clear();
        _errorMessage = e.message;
        _pagination = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _meetings.clear();
        _errorMessage = e.toString();
        _pagination = null;
        _isLoading = false;
      });
    }
  }

  void _handleSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _currentQuery = value.trim();
      _fetchMeetings(page: 1);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _currentQuery = '';
    _fetchMeetings(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      drawer: SpeedViewDrawer(currentRoute: AppRoutes.meetings),
      appBar: const SpeedViewAppBar(title: 'Meetings'),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => _fetchMeetings(page: _pagination?.currentPage ?? 1),
          backgroundColor: const Color(0xFF0F1925),
          color: const Color(0xFFFB4D46),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              MeetingSearchBar(
                controller: _searchController,
                onChanged: _handleSearchChanged,
                onSubmitted: (_) => _fetchMeetings(page: 1),
                onClear: _clearSearch,
              ),
              const SizedBox(height: 14),
              MeetingPaginationControls(
                pagination: _pagination,
                isLoading: _isLoading,
                onPrev: () => _fetchMeetings(
                  page: (_pagination?.currentPage ?? 1) - 1,
                ),
                onNext: () => _fetchMeetings(
                  page: (_pagination?.currentPage ?? 1) + 1,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                _buildLoadingState()
              else if (_errorMessage != null)
                _buildErrorState()
              else if (_meetings.isEmpty)
                _buildEmptyState()
              else
                ..._buildMeetingList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home),
              child: Text(
                'Home',
                style: TextStyle(color: Colors.white.withValues(alpha: .6)),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.white60, size: 18),
            const SizedBox(width: 6),
            const Text(
              'Meetings',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Meetings',
          style: speedViewHeadingStyle(
            context,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Explore every Formula 1 weekend with the exact data served on SpeedView Web.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        )
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: Color(0xFFFB4D46),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF240B0B),
        border: Border.all(color: const Color(0x33FF6B6B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error loading meetings',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _fetchMeetings(page: 1),
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final summary = _currentQuery.isEmpty
        ? 'No meetings are available right now.'
        : 'No meetings found for "$_currentQuery".';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .05)),
        color: const Color(0xFF0F151E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nothing to show',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMeetingList() {
    return [
      for (var i = 0; i < _meetings.length; i++) ...[
        MeetingCard(meeting: _meetings[i]),
        if (i != _meetings.length - 1) const SizedBox(height: 14),
      ],
    ];
  }
}
