import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyUsername = 'auth_username';
  static const String _keyPassword = 'auth_password';
  static const String _keyIsLoggedIn = 'auth_is_logged_in';

  static Future<void> saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  static Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final username = prefs.getString(_keyUsername);
    final password = prefs.getString(_keyPassword);

    if (username != null && password != null && username.isNotEmpty && password.isNotEmpty) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }
}
