import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/user/screens/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Profile Info Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _role = '';
  String _themePreference = 'dark';
  
  // Change Password Controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  
  // Danger Zone Controllers
  final TextEditingController _deletePasswordController = TextEditingController();
  final TextEditingController _deleteConfirmController = TextEditingController();

  bool _isLoading = true;
  final String _baseUrl = "https://helven-marcia-speedview.pbp.cs.ui.ac.id";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _deletePasswordController.dispose();
    _deleteConfirmController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get("$_baseUrl/user/profile-flutter/");
      if (response['status'] == true) {
        setState(() {
          _usernameController.text = response['username'];
          _emailController.text = response['email'];
          _role = response['role'];
          _themePreference = response['theme_preference'];
          _isLoading = false;
        });
      } else {
        _showSnackBar(response['message'] ?? 'Failed to load profile', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _updateProfile() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        "$_baseUrl/user/edit-profile-flutter/",
        jsonEncode({
          'username': _usernameController.text,
          'email': _emailController.text,
          'theme_preference': _themePreference,
        }),
      );

      if (mounted) {
        if (response['status'] == true) {
          _showSnackBar('Profile updated successfully!', Colors.green);
        } else {
          _showSnackBar(response['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _changePassword() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        "$_baseUrl/user/change-password-flutter/",
        jsonEncode({
          'old_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
          'confirm_password': _confirmNewPasswordController.text,
        }),
      );

      if (mounted) {
        if (response['status'] == true) {
          _showSnackBar('Password changed successfully!', Colors.green);
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmNewPasswordController.clear();
        } else {
          _showSnackBar(response['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _deleteAccount() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        "$_baseUrl/user/delete-account-flutter/",
        jsonEncode({
          'password': _deletePasswordController.text,
          'confirm_text': _deleteConfirmController.text,
        }),
      );

      if (mounted) {
        if (response['status'] == true) {
          _showSnackBar('Account deleted successfully', Colors.green);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          _showSnackBar(response['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _logout() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post("$_baseUrl/user/logout-flutter/", {});
      if (mounted) {
        if (response['status'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          _showSnackBar(response['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF161B22),
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Profile Settings', style: TextStyle(color: Color(0xFFE6EDF3))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          ],
        ),
        backgroundColor: const Color(0xFF161B22),
        iconTheme: const IconThemeData(color: Color(0xFFE6EDF3)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: const Color(0xFFE6EDF3),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Profile Information'),
            Tab(text: 'Change Password'),
            Tab(text: 'Danger Zone'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileInfoTab(),
          _buildChangePasswordTab(),
          _buildDangerZoneTab(),
        ],
      ),
    );
  }

  Widget _buildProfileInfoTab() {
    return SingleChildScrollView(
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
                    onPressed: _updateProfile,
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
    );
  }

  Widget _buildChangePasswordTab() {
    return SingleChildScrollView(
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
                  'Change Password',
                  style: TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Update your password to keep your account secure',
                  style: TextStyle(color: Color(0xB3E6EDF3), fontSize: 14),
                ),
                const SizedBox(height: 24),

                _buildLabel('Current Password'),
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Color(0xFFE6EDF3)),
                  decoration: _buildInputDecoration('Enter your current password'),
                ),
                const SizedBox(height: 16),

                _buildLabel('New Password'),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Color(0xFFE6EDF3)),
                  decoration: _buildInputDecoration('Enter your new password'),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Password must be at least 8 characters',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),

                _buildLabel('Confirm New Password'),
                TextField(
                  controller: _confirmNewPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Color(0xFFE6EDF3)),
                  decoration: _buildInputDecoration('Confirm your new password'),
                ),
                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneTab() {
    return SingleChildScrollView(
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
                  'Danger Zone',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Permanently delete your account and all associated data',
                  style: TextStyle(color: Color(0xB3E6EDF3), fontSize: 14),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text(
                            'Delete Account',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Once you delete your account, there is no going back. Please be certain.',
                        style: TextStyle(color: Color(0xB3E6EDF3)),
                      ),
                      const SizedBox(height: 24),

                      _buildLabel('Confirm Password'),
                      TextField(
                        controller: _deletePasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Color(0xFFE6EDF3)),
                        decoration: _buildInputDecoration('Enter your password to confirm'),
                      ),
                      const SizedBox(height: 16),

                      _buildLabel("Type 'DELETE' to confirm"),
                      TextField(
                        controller: _deleteConfirmController,
                        style: const TextStyle(color: Color(0xFFE6EDF3)),
                        decoration: _buildInputDecoration('Type DELETE in capital letters'),
                      ),
                      const SizedBox(height: 24),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _deleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Delete My Account', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
