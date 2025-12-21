import 'package:flutter/material.dart';
import '../models/circuit_model.dart';

class CircuitCard extends StatelessWidget {
  final Circuit circuit;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CircuitCard({
    super.key,
    required this.circuit,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F151F),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // MAP
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Image.network(
                  circuit.mapImageUrl != null && circuit.mapImageUrl!.isNotEmpty
                      ? circuit.mapImageUrl!
                      : 'https://placehold.co/600x400/0D1117/E6EDF3?text=No+Map',
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, error, stackTrace) => const Center(
                    child: Icon(Icons.map, size: 24, color: Colors.grey),
                  ),
                ),
              ),
            ),
            
            // informasi & tombol
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, 
                children: [
                  Text(
                    circuit.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    circuit.country,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // tombol admin
                  if (circuit.isAdmin) ...[
                    const SizedBox(height: 8), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Edit Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onEdit,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.yellow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.edit, size: 16, color: Colors.yellowAccent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                            ),
                          ),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}