import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/common/constants.dart';
import 'package:speedview/user/screens/profile.dart';
import 'package:speedview/user/screens/login.dart';


class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      appBar: AppBar(
        title: const Text('SpeedView', style: TextStyle(color: Color(0xFFE6EDF3))),
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE6EDF3)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.speed,
              size: 100,
              color: Color(0xFFE6EDF3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to SpeedView!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE6EDF3),
              ),
            ),
            const SizedBox(height: 40),


            // tombol profile
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1117),
                  foregroundColor: const Color(0xFFE6EDF3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
                child: const Text('View Profile'),
              ),
            ),
            const SizedBox(height: 16),

            // tombol logout
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () async {
                  final response =
                      await request.logout(buildSpeedViewUrl('/logout-flutter/'));
                  String message = response["message"];
                  if (context.mounted) {
                    if (response['status']) {
                      String uname = response["username"] ?? "";
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("$message Goodbye, $uname."),
                        backgroundColor: Colors.green,
                      ));
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.red,
                      ));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
