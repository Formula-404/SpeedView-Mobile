import 'package:flutter/material.dart';

import '../models/meeting.dart';

class MeetingPaginationControls extends StatelessWidget {
  const MeetingPaginationControls({
    super.key,
    required this.pagination,
    required this.onPrev,
    required this.onNext,
    required this.isLoading,
  });

  final MeetingPagination? pagination;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final page = pagination;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
        color: const Color(0xFF0E141F),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              page == null
                  ? 'Loading meetings…'
                  : page.totalMeetings == 0
                      ? 'No meetings found'
                      : 'Page ${page.currentPage} of ${page.totalPages} • ${page.totalMeetings} meetings',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: .75),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed:
                (page == null || !page.hasPrevious || isLoading) ? null : onPrev,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: const Text('Prev'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: (page == null || !page.hasNext || isLoading) ? null : onNext,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
