// lib/comparison/screens/comparison_list_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/Comparison.dart';
import '../widgets/comparison_card.dart';

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
    final scopeParam = scope == ComparisonScope.mine ? 'my' : 'all';

    final uri = Uri.parse(
      '${widget.apiBaseUrl}/comparison/api/list/?scope=$scopeParam',
    );

    final res = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      // Attempt to parse error if body is JSON; otherwise throw generic.
      throw Exception('Failed with status ${res.statusCode}');
    }

    return Comparison.listFromResponseBody(res.body);
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
    final bgColor = const Color(0xFF010409);
    final red = const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const BackButton(
          color: Colors.white,
        ),
        title: const Text(
          'Comparisons',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE6EDF3),
          ),
        ),
        actions: [
          if (widget.onCreatePressed != null)
            IconButton(
              icon: const Icon(Icons.add),
              color: Colors.white,
              onPressed: widget.onCreatePressed,
              tooltip: 'Create Comparison',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
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
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final cmp = items[index];
                              return ComparisonCard(
                                comparison: cmp,
                                onTap: () {
                                  // TODO: navigate to detail screen
                                  // You already have cmp.detailUrl from backend
                                  // which might map to a webview or deeplink.
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: const Text(
                'No comparisons listed.',
                style: TextStyle(
                  color: Color(0xB3E6EDF3),
                  fontSize: 14,
                ),
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
              padding: const EdgeInsets.all(16),
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
        color: selected
            ? _red
            : Colors.grey.shade800.withOpacity(0.5),
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
                  color: selected
                      ? Colors.white
                      : const Color(0xCCE6EDF3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
