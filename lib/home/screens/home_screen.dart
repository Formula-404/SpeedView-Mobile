// lib/home/screens/home_screen.dart
import 'package:flutter/material.dart';

import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';

// override tujuan tombol tertentu
import 'package:speedview/driver/screens/driver_list_page.dart';
import 'package:speedview/laps/screens/laps_list_page.dart';
import 'package:speedview/pit/screens/pit_list_page.dart';
import 'package:speedview/user/screens/profile.dart';

import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/user/screens/login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = 'User';
  String _role = 'User';
  final String _baseUrl = "http://127.0.0.1:8000";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get("$_baseUrl/profile-flutter/");
      if (response['status'] == true) {
        if (mounted) {
          setState(() {
            _username = response['username'];
            _role = response['role'];
          });
        }
      }
    } catch (e) {
      // Silent error or retry
    }
  }

  Future<void> _logout() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post("$_baseUrl/logout-flutter/", {});
      if (mounted) {
        if (response['status'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message']), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SpeedViewDrawer(currentRoute: AppRoutes.home),
      appBar: SpeedViewAppBar(
        title: 'SpeedView Home',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            offset: const Offset(0, 50),
            color: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white24),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _role == 'admin' ? Colors.red.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _role == 'admin' ? Colors.red.withValues(alpha: 0.5) : Colors.blue.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _role.toUpperCase(),
                        style: TextStyle(
                          color: _role == 'admin' ? Colors.red[400] : Colors.blue[400],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white24),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Text('Profile', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Log Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
                    onTap: () {
                      // ⬇️ Khusus beberapa kartu, kita arahkan ke halaman Flutter custom
                      if (destination.title == 'Drivers') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DriverListPage(),
                          ),
                        );
                      } else if (destination.title == 'Laps') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LapsListPage(),
                          ),
                        );
                      } else if (destination.title == 'Pit Stops' ||
                          destination.title == 'Pit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PitListPage(),
                          ),
                        );
                      } else if (destination.title == 'Profile') {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                      } else {
                        // yang lain tetap pakai routing lama
                        Navigator.of(context)
                            .pushReplacementNamed(destination.route);
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2 - 30,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              Colors.white.withValues(alpha: .08),
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
