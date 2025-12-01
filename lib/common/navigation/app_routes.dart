import 'package:flutter/material.dart';

class DrawerDestination {
  const DrawerDestination({
    required this.route,
    required this.title,
    required this.icon,
    this.description,
    this.implemented = false,
  });

  final String route;
  final String title;
  final IconData icon;
  final String? description;
  final bool implemented;
}

class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String meetings = '/meetings';
  static const String sessions = '/sessions';
  static const String drivers = '/drivers';
  static const String teams = '/teams';
  static const String cars = '/cars';
  static const String circuits = '/circuits';
  static const String laps = '/laps';
  static const String pit = '/pit';

  // alias biar baris:
  // drawer: SpeedViewDrawer(currentRoute: AppRoutes.pitStops)
  // bisa jalan tanpa ngubah file lain
  static const String pitStops = pit;

  static const String comparison = '/comparison';
  static const String user = '/user';

  static const List<DrawerDestination> destinations = [
    DrawerDestination(
      route: home,
      title: 'Home',
      icon: Icons.dashboard_outlined,
      description: 'SpeedView overview hub',
      implemented: true,
    ),
    DrawerDestination(
      route: user,
      title: 'Profile',
      icon: Icons.person_outline,
      description: 'Account & preferences',
      implemented: true,
    ),
    DrawerDestination(
      route: meetings,
      title: 'Meetings',
      icon: Icons.event_note_outlined,
      description: 'Grand Prix weekend data',
      implemented: true,
    ),
    DrawerDestination(
      route: sessions,
      title: 'Sessions',
      icon: Icons.schedule_outlined,
      description: 'Practice, Quali, Race timelines',
      implemented: false,
    ),
    DrawerDestination(
      route: drivers,
      title: 'Drivers',
      icon: Icons.sports_motorsports_outlined,
      description: 'Driver stats & profiles',
      implemented: true, // sudah ada DriverListPage
    ),
    DrawerDestination(
      route: teams,
      title: 'Teams',
      icon: Icons.handshake_outlined,
      description: 'Constructor details',
      implemented: false,
    ),
    DrawerDestination(
      route: cars,
      title: 'Cars',
      icon: Icons.car_rental_outlined,
      description: 'Technical breakdown',
      implemented: false,
    ),
    DrawerDestination(
      route: circuits,
      title: 'Circuits',
      icon: Icons.route_outlined,
      description: 'Track layouts & metadata',
      implemented: true, // modul circuits sudah jalan
    ),
    DrawerDestination(
      route: laps,
      title: 'Laps',
      icon: Icons.speed_outlined,
      description: 'Lap-by-lap analytics',
      implemented: true, // LapsListPage
    ),
    DrawerDestination(
      route: pit,
      title: 'Pit Stops',
      icon: Icons.build_outlined,
      description: 'Strategy and timing',
      implemented: true, // PitListPage
    ),
    DrawerDestination(
      route: comparison,
      title: 'Comparison',
      icon: Icons.compare_arrows_outlined,
      description: 'Head-to-head insights',
      implemented: false,
    ),
  ];

  static DrawerDestination? byRoute(String? route) {
    if (route == null) return null;
    try {
      return destinations.firstWhere((dest) => dest.route == route);
    } catch (_) {
      return null;
    }
  }

  static Iterable<DrawerDestination> get placeholderDestinations =>
      destinations.where((destination) => !destination.implemented);
}
