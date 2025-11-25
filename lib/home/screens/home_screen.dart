import 'package:flutter/material.dart';

import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SpeedViewDrawer(currentRoute: AppRoutes.home),
      appBar: const SpeedViewAppBar(title: 'SpeedView Home'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeroCard(context),
          const SizedBox(height: 24),
          Text(
            'Explore Modules',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppRoutes.destinations
                .where((dest) => dest.route != AppRoutes.home)
                .map(
                  (destination) => GestureDetector(
                    onTap: () => Navigator.of(context)
                        .pushReplacementNamed(destination.route),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2 - 30,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .08),
                        ),
                        color: const Color(0xFF0F151E),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(destination.icon, color: Colors.white70),
                          const SizedBox(height: 12),
                          Text(
                            destination.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            destination.description ?? 'Coming soon',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFB4D46), Color(0xFFFF7A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: .4),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SpeedView Mobile',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dive into Formula 1 data anywhere. Use the menu to jump between meetings, drivers, circuits, and more.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
