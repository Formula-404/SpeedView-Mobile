import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/user/constants.dart';
import 'package:speedview/user/screens/login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

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
                    const Icon(
                      Icons.speed,
                      size: 64,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF161B22),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your account to get started',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Choose a username',
                        labelStyle: const TextStyle(color: Colors.black54),
                        hintStyle: const TextStyle(color: Colors.black38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.black45, width: 1.0),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.red, width: 2.0),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        labelStyle: const TextStyle(color: Colors.black54),
                        hintStyle: const TextStyle(color: Colors.black38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.black45, width: 1.0),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.red, width: 2.0),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Create a password',
                        labelStyle: const TextStyle(color: Colors.black54),
                        hintStyle: const TextStyle(color: Colors.black38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.black45, width: 1.0),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.red, width: 2.0),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20.0),
                    TextField(
                      controller: _confirmPasswordController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Confirm your password',
                        labelStyle: const TextStyle(color: Colors.black54),
                        hintStyle: const TextStyle(color: Colors.black38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.black45, width: 1.0),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.red, width: 2.0),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32.0),
                    ElevatedButton(
                      onPressed: () async {
                        String username = _usernameController.text;
                        String password = _passwordController.text;
                        String confirmPassword = _confirmPasswordController.text;
                        String email = _emailController.text;

                        if (password != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Passwords do not match!"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final response = await request.postJson(
                          buildSpeedViewUrl('/register-flutter/'),
                          jsonEncode(<String, String>{
                            'username': username,
                            'password': password,
                            'email': email,
                          }),
                        );

                        if (response['status'] == true) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Registration successful! Please login."),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Registration Failed'),
                                content: Text(response['message']),
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
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF111827),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
