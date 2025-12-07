import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/Comparison.dart';
import '../widgets/comparison_card.dart';

import 'comparison_team_detail_screen.dart';
import 'comparison_driver_detail_screen.dart';
import 'comparison_circuit_detail_screen.dart';

enum ComparisonScope { all, mine }

class ComparisonListScreen extends StatefulWidget {
  const ComparisonListScreen({
    Key? key,
    this.onCreatePressed,
    this.apiBaseUrl = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id',
  }) : super(key: key);

  final VoidCallback? onCreatePressed;
  final String apiBaseUrl;

  @override
  State<ComparisonListScreen> createState() => _ComparisonListScreenState();
}

class _ComparisonListScreenState extends State<ComparisonListScreen> {
  ComparisonScope _scope = ComparisonScope.all;
  late Future<List<Comparison>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchComparisons(_scope);
  }

  Future<List<Comparison>> _fetchComparisons(ComparisonScope scope) async {
  final request = context.read<CookieRequest>();

  final scopeParam = scope == ComparisonScope.mine ? 'my' : 'all';

  final response = await request.get(
    '${widget.apiBaseUrl}/comparison/api/list/?scope=$scopeParam',
  );

  if (response['ok'] != true) {
    throw Exception(response['error'] ?? 'Failed to load comparisons');
  }

  return Comparison.listFromJson(response['data']);
}

  void _changeScope(ComparisonScope scope) {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _future = _fetchComparisons(scope);
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
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
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/',
                                  (route) => false,
                                );
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
                        const Text(
                          'Comparisons',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onCreatePressed != null)
                    IconButton(
                      onPressed: widget.onCreatePressed,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // TABS
              Row(
                children: [
                  Expanded(
                    child: _ScopeButton(
                      label: 'All Comparisons',
                      selected: _scope == ComparisonScope.all,
                      onTap: () => _changeScope(ComparisonScope.all),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScopeButton(
                      label: 'My Comparisons',
                      selected: _scope == ComparisonScope.mine,
                      onTap: () => _changeScope(ComparisonScope.mine),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // CONTENT
              Expanded(
                child: FutureBuilder<List<Comparison>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    final items = snapshot.data ?? const <Comparison>[];

                    if (items.isEmpty) {
                      return _buildEmptyState();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${items.length} comparison${items.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0x99E6EDF3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final cmp = items[index];

                              return ComparisonCard(
                                comparison: cmp,
                                onTap: () {
                                  if (cmp.module == 'team') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ComparisonTeamDetailScreen(
                                          comparison: cmp,
                                          apiBaseUrl: widget.apiBaseUrl,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
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

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Loading comparisons…',
          style: TextStyle(
            fontSize: 12,
            color: Color(0x99E6EDF3),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '0 comparisons',
          style: TextStyle(
            fontSize: 12,
            color: Color(0x99E6EDF3),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: const Text(
                'No comparisons listed.',
                style: TextStyle(
                  color: Color(0xB3E6EDF3),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Error',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFEF4444),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withOpacity(0.4),
                ),
              ),
              child: Text(
                'Network error while loading comparisons.\n\n$message',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFF9CA3),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScopeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeButton({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  Color get _red => const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final baseBorderRadius = BorderRadius.circular(999);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: baseBorderRadius,
        color: selected ? _red : Colors.grey.shade800.withOpacity(0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: baseBorderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xCCE6EDF3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
