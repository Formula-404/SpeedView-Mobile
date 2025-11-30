import 'package:flutter/material.dart';
import '../models/team_model.dart';

class TeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isAdmin;

  const TeamCard({
    super.key,
    required this.team,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.isAdmin = false,
  });

  Color _parseColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF0F151F);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          team.teamLogoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, error, stack) => const Icon(
                            Icons.broken_image, 
                            color: Colors.white24,
                            size: 20
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Name & Short Code
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.teamName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Text(
                                  team.shortCode,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${team.country} • ${team.base}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    // Primary Color
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: _parseColor(team.teamColourHex),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      team.teamColourHex,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    
                    // Secondary Color
                    if (team.teamColourSecondaryHex.isNotEmpty) ...[
                      Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: _parseColor(team.teamColourSecondaryHex),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        team.teamColourSecondaryHex,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                    ],

                    const Spacer(),

                    // Active Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: team.isActive 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: team.isActive 
                              ? Colors.green.withOpacity(0.4) 
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        team.isActive ? "ACTIVE" : "INACTIVE",
                        style: TextStyle(
                          color: team.isActive ? Colors.greenAccent : Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Admin Actions (Delete/Edit)
                if (isAdmin) ...[
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16, color: Colors.blueAccent),
                        label: const Text("Edit", style: TextStyle(color: Colors.blueAccent)),
                      ),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                        label: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}