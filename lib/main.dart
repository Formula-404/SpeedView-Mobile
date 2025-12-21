import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/navigation/bottom_nav_shell.dart';
import 'package:speedview/common/screens/coming_soon_screen.dart';
import 'package:speedview/common/theme/typography.dart';
import 'package:speedview/user/screens/login.dart';

import 'car/screens/car_list_screen.dart';
import 'car/screens/car_manual_entries_screen.dart';
import 'meeting/meeting_service.dart';
import 'meeting/screens/meeting_list_screen.dart';
import 'session/screens/session_list_screen.dart';
import 'circuit/screens/circuit_list_screen.dart';
import 'team/screens/team_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpeedViewApp());
}

class SpeedViewApp extends StatefulWidget {
  const SpeedViewApp({
    super.key,
    this.service,
    this.initialRoute = AppRoutes.login,
  });

  final MeetingService? service;
  final String initialRoute;

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
              body: Center(
                child: CircularProgressIndicator(),
              ),
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
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.home: (_) =>
            const BottomNavigationShell(initialRoute: AppRoutes.home),
        AppRoutes.comparison: (_) =>
            const BottomNavigationShell(initialRoute: AppRoutes.comparison),
        AppRoutes.user: (_) =>
            const BottomNavigationShell(initialRoute: AppRoutes.user),
        AppRoutes.meetings: (_) => MeetingListScreen(service: widget.service),
        AppRoutes.sessions: (context) => const SessionListScreen(),
        AppRoutes.circuits: (context) => const CircuitListScreen(),
        AppRoutes.cars: (_) => const CarListScreen(),
        AppRoutes.carManual: (_) => const CarManualEntriesScreen(),
        AppRoutes.teams: (_) => const TeamListScreen(),
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
