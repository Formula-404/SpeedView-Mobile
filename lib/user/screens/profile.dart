import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _role = '';
  String _themePreference = 'dark';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get("http://127.0.0.1:8000/profile-flutter/");
      if (response['status'] == true) {
        setState(() {
          _usernameController.text = response['username'];
          _emailController.text = response['email'];
          _role = response['role'];
          _themePreference = response['theme_preference'];
          _isLoading = false;
        });
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF161B22),
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      appBar: AppBar(
        title: const Text('Profile Settings', style: TextStyle(color: Color(0xFFE6EDF3))),
        backgroundColor: const Color(0xFF161B22),
        iconTheme: const IconThemeData(color: Color(0xFFE6EDF3)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage your account settings and preferences',
              style: TextStyle(color: Color(0xB3E6EDF3), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Update your account information',
                    style: TextStyle(color: Color(0xB3E6EDF3), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  
                  // Role Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Role',
                              style: TextStyle(color: Color(0xB3E6EDF3), fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _role == 'admin' ? 'Administrator' : 'User',
                              style: TextStyle(
                                color: _role == 'admin' ? Colors.red[400] : Colors.blue[400],
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _role == 'admin'
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _role == 'admin'
                                  ? Colors.red.withValues(alpha: 0.5)
                                  : Colors.blue.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            _role.toUpperCase(),
                            style: TextStyle(
                              color: _role == 'admin' ? Colors.red[400] : Colors.blue[400],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Fields
                  _buildLabel('Username'),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Color(0xFFE6EDF3)),
                    decoration: _buildInputDecoration(''),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Email address'),
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Color(0xFFE6EDF3)),
                    decoration: _buildInputDecoration(''),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Theme Preference'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _themePreference,
                        dropdownColor: const Color(0xFF161B22),
                        isExpanded: true,
                        style: const TextStyle(color: Color(0xFFE6EDF3)),
                        items: const [
                          DropdownMenuItem(value: 'light', child: Text('Light')),
                          DropdownMenuItem(value: 'dark', child: Text('Dark')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _themePreference = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        final response = await request.postJson(
                          "http://127.0.0.1:8000/edit-profile-flutter/",
                          jsonEncode({
                            'username': _usernameController.text,
                            'email': _emailController.text,
                            'theme_preference': _themePreference,
                          }),
                        );

                        if (context.mounted) {
                          if (response['status'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(response['message']),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE6EDF3),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF161B22),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
