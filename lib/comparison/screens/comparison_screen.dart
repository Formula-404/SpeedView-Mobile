import 'package:flutter/material.dart';

import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/screens/coming_soon_screen.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final destination = AppRoutes.byRoute(AppRoutes.comparison);

    if (destination == null) {
      return const Scaffold(
        body: Center(
          child: Text('Comparison module will be available soon'),
        ),
      );
    }

    return ComingSoonScreen(destination: destination);
  }
}
