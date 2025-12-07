import 'package:flutter/material.dart';
import '../models/Comparison.dart';

class ComparisonCard extends StatelessWidget {
  final Comparison comparison;
  final VoidCallback? onTap;

  const ComparisonCard({
    Key? key,
    required this.comparison,
    this.onTap,
  }) : super(key: key);

  Color get _cardBg => const Color(0xFF0D1117); 
  Color get _borderColor => const Color(0xFF374151); 

  @override
  Widget build(BuildContext context) {
    final subjectList =
        comparison.items.isNotEmpty ? comparison.items.join(', ') : '—';

    final isPublic = comparison.isPublic;
    final badgeText = isPublic ? 'PUBLIC' : 'PRIVATE';

    final badgeBorderColor =
        isPublic ? Colors.green.withOpacity(0.4) : Colors.white.withOpacity(0.2);
    final badgeBgColor =
        isPublic ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05);
    final badgeTextColor =
        isPublic ? Colors.greenAccent.shade200 : Colors.white.withOpacity(0.7);

    final createdLabel = _formatDate(comparison.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          comparison.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE6EDF3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: badgeBgColor,
                          border: Border.all(color: badgeBorderColor, width: 0.8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (createdLabel.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    createdLabel,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFFE6EDF3).withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 4),

            Text(
              'Module: ${comparison.moduleLabel} • $subjectList',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xB3E6EDF3), 
              ),
            ),

            const SizedBox(height: 4),

            
            Text(
              'By ${comparison.ownerName}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0x99E6EDF3), 
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${_month(dt.month)} ${_two(dt.day)}, ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (m < 1 || m > 12) return '';
    return months[m - 1];
  }
}
