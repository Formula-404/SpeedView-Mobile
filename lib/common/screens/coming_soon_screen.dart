import 'package:flutter/material.dart';

import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.destination,
  });

  final DrawerDestination destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SpeedViewDrawer(currentRoute: destination.route),
      appBar: SpeedViewAppBar(title: destination.title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(destination.icon, size: 84, color: Colors.white54),
              const SizedBox(height: 20),
              Text(
                '${destination.title} module',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                destination.description ??
                    'This module will be available on mobile soon.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.home),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
