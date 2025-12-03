import 'package:flutter/material.dart';
import '../models/team.dart';

class TeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback? onTap;

  const TeamCard({
    super.key,
    required this.team,
    this.onTap,
  });

  Color _parseColor(String hex) {
    if (hex.isEmpty) return Colors.transparent;
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) return Colors.transparent;
    return Color(int.parse('FF$clean', radix: 16));
  }

  String _countryDisplay() {
    final parts = <String>[];
    if (team.country.isNotEmpty) parts.add(team.country);
    if (team.base.isNotEmpty) parts.add(team.base);
    return parts.join(' • ');
  }

  String _resolveLogoUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    // Treat as relative path from your Django host
    const base = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id';
    if (raw.startsWith('/')) {
      return '$base$raw';
    }
    return '$base/$raw';
  }

  @override
  Widget build(BuildContext context) {
    final primary = _parseColor(team.teamColourHex);
    final secondary = team.teamColourSecondaryHex.isNotEmpty
        ? _parseColor(team.teamColourSecondaryHex)
        : _parseColor(team.teamColourSecondary);

    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117).withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // mobile-friendly height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: logo + name + shortcode + active
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLogo(primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              team.teamName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _codeBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _countryDisplay().isNotEmpty
                            ? _countryDisplay()
                            : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            const SizedBox(height: 10),

            // Bottom row: colors + active badge
            Row(
              children: [
                _colorSwatch(
                  primary,
                  team.teamColourHex.isNotEmpty
                      ? team.teamColourHex
                      : '—',
                ),
                const SizedBox(width: 8),
                _colorSwatch(
                  secondary,
                  (team.teamColourSecondaryHex.isNotEmpty ||
                          team.teamColourSecondary.isNotEmpty)
                      ? (team.teamColourSecondaryHex.isNotEmpty
                          ? team.teamColourSecondaryHex
                          : '#${team.teamColourSecondary}')
                      : '—',
                ),
                const Spacer(),
                _buildActiveBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(Color primary) {
    final fallback = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: primary == Colors.transparent
            ? Colors.white.withOpacity(0.04)
            : primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        team.shortCode.isNotEmpty
            ? team.shortCode
            : (team.teamName.isNotEmpty ? team.teamName[0] : '?'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (team.teamLogoUrl.isEmpty) return fallback;

    final url = _resolveLogoUrl(team.teamLogoUrl);
    if (url.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  Widget _codeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Text(
        team.shortCode.isNotEmpty ? team.shortCode : '—',
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xB3FFFFFF),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _colorSwatch(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color == Colors.transparent
                ? Colors.transparent
                : color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label.isNotEmpty ? label : '—',
          style: const TextStyle(
            fontSize: 10,
            color: Color(0x99FFFFFF),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveBadge() {
    if (team.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x6622C55E)),
          color: const Color(0x1A22C55E),
        ),
        child: const Text(
          'ACTIVE',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF4ADE80),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          color: Colors.white.withOpacity(0.05),
        ),
        child: const Text(
          'INACTIVE',
          style: TextStyle(
            fontSize: 10,
            color: Color(0x99FFFFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }
}
