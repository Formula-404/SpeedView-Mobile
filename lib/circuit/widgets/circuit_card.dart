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
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map
            Container(
              height: 140,
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Image.network(
                circuit.mapImageUrl != null && circuit.mapImageUrl!.isNotEmpty
                    ? circuit.mapImageUrl!
                    : 'https://placehold.co/600x400/0D1117/E6EDF3?text=No+Map',
                fit: BoxFit.contain,
                errorBuilder: (ctx, error, stackTrace) => const Center(
                  child: Icon(Icons.map, size: 50, color: Colors.grey),
                ),
              ),
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    circuit.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${circuit.location}, ${circuit.country}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Admin Actions
                  if (circuit.isAdmin && circuit.isAdminCreated) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.white10),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: onEdit,
                          child: const Text(
                            'EDIT',
                            style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: onDelete,
                          child: const Text(
                            'DELETE',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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