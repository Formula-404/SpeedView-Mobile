import 'package:flutter/material.dart';

import 'package:speedview/common/navigation/app_routes.dart';

class SpeedViewDrawer extends StatelessWidget {
  const SpeedViewDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF060A12),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(color: Color(0x22FFFFFF)),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: AppRoutes.destinations.length,
                itemBuilder: (context, index) {
                  final destination = AppRoutes.destinations[index];
                  final selected = destination.route == currentRoute;
                  return ListTile(
                    leading: Icon(
                      destination.icon,
                      color: selected ? Colors.white : Colors.white70,
                    ),
                    title: Text(
                      destination.title,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: .9),
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    subtitle: destination.description == null
                        ? null
                        : Text(
                            destination.description!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .6),
                              fontSize: 12,
                            ),
                          ),
                    selected: selected,
                    selectedTileColor: const Color(0x22FFFFFF),
                    onTap: () {
                      Navigator.of(context).pop();
                      if (!selected) {
                        Navigator.of(context)
                            .pushReplacementNamed(destination.route);
                      }
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'SpeedView Mobile • ${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: .5),
                  letterSpacing: .6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SpeedView',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Formula 1 insights hub',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
