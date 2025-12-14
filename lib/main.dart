import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/navigation/bottom_nav_shell.dart';
import 'package:speedview/common/screens/coming_soon_screen.dart';
import 'package:speedview/common/services/auth_service.dart';
import 'package:speedview/common/theme/typography.dart';
import 'package:speedview/common/widgets/auth_guard.dart';
import 'package:speedview/user/constants.dart';
import 'package:speedview/user/screens/login.dart';

import 'car/screens/car_list_screen.dart';
import 'car/screens/car_manual_entries_screen.dart';
import 'meeting/meeting_service.dart';
import 'meeting/screens/meeting_list_screen.dart';
import 'session/screens/session_list_screen.dart';
import 'circuit/screens/circuit_list_screen.dart';
import 'team/screens/team_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpeedViewApp());
}

class SpeedViewApp extends StatelessWidget {
  const SpeedViewApp({
    super.key,
    this.service,
  });

  final MeetingService? service;

  static const Color _primaryRed = Color(0xFFFB4D46);
  static const Color _accentOrange = Color(0xFFFFB368);
  static const Color _background = Color(0xFF05070B);
  static const Color _surface = Color(0xFF0F151F);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.dark(
      primary: _primaryRed,
      secondary: _accentOrange,
      surface: _surface,
    );

    final placeholderRoutes = AppRoutes.placeholderDestinations
        .map((destination) => destination.route)
        .toSet();

    return Provider<CookieRequest>(
      create: (_) => CookieRequest(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SpeedView Mobile',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          scaffoldBackgroundColor: _background,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontFamily: speedViewHeadingFontFamily,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              fontSize: 20,
            ),
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ).apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: _primaryRed,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        home: SplashScreen(service: service),
        routes: {
          AppRoutes.login: (_) => const LoginPage(),
          AppRoutes.home: (_) =>
              const AuthGuard(child: BottomNavigationShell(initialRoute: AppRoutes.home)),
          AppRoutes.comparison: (_) =>
              const AuthGuard(child: BottomNavigationShell(initialRoute: AppRoutes.comparison)),
          AppRoutes.user: (_) =>
              const AuthGuard(child: BottomNavigationShell(initialRoute: AppRoutes.user)),
          AppRoutes.meetings: (_) => AuthGuard(child: MeetingListScreen(service: service)),
          AppRoutes.sessions: (context) => const AuthGuard(child: SessionListScreen()),
          AppRoutes.circuits: (context) => const AuthGuard(child: CircuitListScreen()),
          AppRoutes.cars: (_) => const AuthGuard(child: CarListScreen()),
          AppRoutes.carManual: (_) => const AuthGuard(child: CarManualEntriesScreen()),
          AppRoutes.teams: (_) => const AuthGuard(child: TeamListScreen()),
        },
        onGenerateRoute: (settings) {
          if (placeholderRoutes.contains(settings.name)) {
            final destination = AppRoutes.byRoute(settings.name);
            if (destination != null) {
              return MaterialPageRoute(
                builder: (_) => ComingSoonScreen(destination: destination),
                settings: settings,
              );
            }
          }
          return null;
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final MeetingService? service;

  const SplashScreen({super.key, this.service});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final credentials = await AuthService.getSavedCredentials();

    if (!mounted) return;

    if (credentials != null) {
      final request = context.read<CookieRequest>();
      try {
        final response = await request.login(
          buildSpeedViewUrl('/login-flutter/'),
          {
            'username': credentials['username'],
            'password': credentials['password'],
          },
        );

        if (!mounted) return;

        if (request.loggedIn) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
          return;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://i.imgur.com/30t6yrY.png',
              height: 120,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB4D46)),
            ),
          ],
        ),
      ),
    );
  }
}
