import 'package:flutter/material.dart';

import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/comparison/screens/comparison_screen.dart';
import 'package:speedview/home/screens/home_screen.dart';
import 'package:speedview/user/screens/profile.dart';

class BottomNavigationShell extends StatefulWidget {
  const BottomNavigationShell({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  State<BottomNavigationShell> createState() => _BottomNavigationShellState();
}

class _BottomNavigationShellState extends State<BottomNavigationShell> {
  static final List<_ShellDestination> _destinations = [
    _ShellDestination(
      route: AppRoutes.comparison,
      label: 'Comparison',
      icon: Icons.compare_arrows_outlined,
      selectedIcon: Icons.compare_arrows,
      builder: () => const ComparisonScreen(),
    ),
    _ShellDestination(
      route: AppRoutes.home,
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      builder: () => const HomeScreen(),
    ),
    _ShellDestination(
      route: AppRoutes.user,
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      builder: () => const ProfilePage(),
    ),
  ];

  late int _currentIndex;
  final Map<int, Widget> _pages = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = _indexForRoute(widget.initialRoute);
    _pages[_currentIndex] = _destinations[_currentIndex].builder();
  }

  @override
  void didUpdateWidget(covariant BottomNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRoute != widget.initialRoute) {
      final nextIndex = _indexForRoute(widget.initialRoute);
      if (nextIndex != _currentIndex) {
        _pages.putIfAbsent(nextIndex, () => _destinations[nextIndex].builder());
        setState(() => _currentIndex = nextIndex);
      }
    }
  }

  int _indexForRoute(String route) {
    final index =
        _destinations.indexWhere((destination) => destination.route == route);
    return index == -1 ? 1 : index;
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) return;
    _pages.putIfAbsent(index, () => _destinations[index].builder());
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = List<Widget>.generate(
      _destinations.length,
      (index) => _pages[index] ?? const SizedBox.shrink(),
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F151F),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: .08)),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            indicatorColor: colorScheme.primary.withValues(alpha: .14),
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: _destinations
                .map(
                  (destination) => NavigationDestination(
                    icon: Icon(destination.icon, color: Colors.white70),
                    selectedIcon:
                        Icon(destination.selectedIcon, color: Colors.white),
                    label: destination.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;
}
