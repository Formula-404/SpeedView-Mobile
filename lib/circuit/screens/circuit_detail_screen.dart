import 'package:flutter/material.dart';
import '../models/circuit_model.dart';

class CircuitDetailScreen extends StatelessWidget {
  final Circuit circuit;

  const CircuitDetailScreen({super.key, required this.circuit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(circuit.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Image
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Image.network(
                circuit.mapImageUrl != null && circuit.mapImageUrl!.isNotEmpty
                    ? circuit.mapImageUrl!
                    : 'https://placehold.co/600x400/0D1117/E6EDF3?text=No+Map',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),

            // Specifications
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F151F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Circuit Specifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Grid Info
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _buildInfoItem('Location', circuit.location),
                      _buildInfoItem('Country', circuit.country),
                      _buildInfoItem('Type', circuit.circuitType),
                      _buildInfoItem('Direction', circuit.direction == 'CW' ? 'Clockwise' : 'Anti-clockwise'),
                      _buildInfoItem('Length', '${circuit.lengthKm} km'),
                      _buildInfoItem('Turns', '${circuit.turns}'),
                      _buildInfoItem('Grands Prix Held', '${circuit.grandsPrixHeld}'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  
                  _buildFullRowItem('Grands Prix Names', circuit.grandsPrix),
                  const SizedBox(height: 16),
                  _buildFullRowItem('Seasons Hosted', circuit.seasons),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildFullRowItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ],
    );
  }
}