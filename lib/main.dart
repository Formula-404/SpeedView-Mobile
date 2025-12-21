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
import 'circuit/screens/circuit_list_screen.dart';
import 'meeting/meeting_service.dart';
import 'meeting/screens/meeting_list_screen.dart';
import 'session/screens/session_list_screen.dart';
import 'team/screens/team_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpeedViewApp());
}

class SpeedViewApp extends StatefulWidget {
  const SpeedViewApp({
    super.key,
    this.service,
    this.initialRoute = splashRoute,
  });

  final MeetingService? service;
  final String initialRoute;

  static const String splashRoute = '/splash';
  static const Color _primaryRed = Color(0xFFFB4D46);
  static const Color _accentOrange = Color(0xFFFFB368);
  static const Color _background = Color(0xFF05070B);
  static const Color _surface = Color(0xFF0F151F);

  @override
  State<SpeedViewApp> createState() => _SpeedViewAppState();
}

class _SpeedViewAppState extends State<SpeedViewApp> {
  final CookieRequest _cookieRequest = CookieRequest();
  late final Future<void> _initialization =
      _cookieRequest.init().then((_) {});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: SpeedViewApp._background,
              colorScheme: const ColorScheme.dark(),
            ),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final initialRoute = _cookieRequest.loggedIn
            ? AppRoutes.home
            : widget.initialRoute;

        return Provider<CookieRequest>.value(
          value: _cookieRequest,
          child: _buildApp(initialRoute),
        );
      },
    );
  }

  Widget _buildApp(String initialRoute) {
    final colorScheme = ColorScheme.dark(
      primary: SpeedViewApp._primaryRed,
      secondary: SpeedViewApp._accentOrange,
      surface: SpeedViewApp._surface,
    );

    final placeholderRoutes = AppRoutes.placeholderDestinations
        .map((destination) => destination.route)
        .toSet();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpeedView Mobile',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: SpeedViewApp._background,
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
            backgroundColor: SpeedViewApp._primaryRed,
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
      initialRoute: initialRoute,
      routes: {
        SpeedViewApp.splashRoute: (_) => SplashScreen(service: widget.service),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.home: (_) => const AuthGuard(
              child: BottomNavigationShell(initialRoute: AppRoutes.home),
            ),
        AppRoutes.comparison: (_) => const AuthGuard(
              child: BottomNavigationShell(
                initialRoute: AppRoutes.comparison,
              ),
            ),
        AppRoutes.user: (_) => const AuthGuard(
              child: BottomNavigationShell(initialRoute: AppRoutes.user),
            ),
        AppRoutes.meetings: (_) =>
            AuthGuard(child: MeetingListScreen(service: widget.service)),
        AppRoutes.sessions: (_) =>
            const AuthGuard(child: SessionListScreen()),
        AppRoutes.circuits: (_) =>
            const AuthGuard(child: CircuitListScreen()),
        AppRoutes.cars: (_) => const AuthGuard(child: CarListScreen()),
        AppRoutes.carManual: (_) =>
            const AuthGuard(child: CarManualEntriesScreen()),
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
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.service});

  final MeetingService? service;

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
    if (!mounted) return;

    final request = context.read<CookieRequest>();
    if (request.loggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }

    final credentials = await AuthService.getSavedCredentials();

    if (!mounted) return;

    if (credentials != null) {
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
          final uname = response['username'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, $uname!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.home);
          return;
        }
      } catch (_) {
        // fall through to login screen
      }
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
