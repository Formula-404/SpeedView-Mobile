import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:speedview/user/constants.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/user/screens/register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 10,
              shadowColor: Colors.black26,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    const Icon(
                      Icons.speed,
                      size: 64,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF161B22),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to your account to continue',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Username
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        labelStyle: const TextStyle(color: Colors.black54),
                        hintStyle: const TextStyle(color: Colors.black38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: Colors.black45,
                            width: 1.0,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2.0,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Password
                    TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.black),
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        labelStyle: const TextStyle(color: Colors.black54),
                        hintStyle: const TextStyle(color: Colors.black38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: Colors.black45,
                            width: 1.0,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2.0,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Button login
                    ElevatedButton(
                      onPressed: () async {
                        final username = _usernameController.text;
                        final password = _passwordController.text;

                        final response = await request.login(
                          buildSpeedViewUrl('/login-flutter/'),
                          {
                            'username': username,
                            'password': password,
                          },
                        );

                        if (request.loggedIn) {
                          final message = response['message'] as String;
                          final uname = response['username'] as String;
                          if (!mounted) return;

                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.home,
                          );

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text('$message Welcome, $uname.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                        } else {
                          if (!mounted) return;
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Login Failed'),
                              content: Text(
                                (response['message'] ?? 'Login failed.')
                                    .toString(),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF111827),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16.0),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Link register
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style:
                              TextStyle(color: Colors.grey, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
