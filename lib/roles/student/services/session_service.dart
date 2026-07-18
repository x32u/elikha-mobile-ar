import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyUserInfo = 'userInfo';

  static Future<void> saveUserInfo({
    required String name,
    required int grade,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'name': name,
      'grade': grade,
      'email': email,
    });
    await prefs.setString(_keyUserInfo, payload);
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserInfo);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<bool> isLoggedIn() async {
    return (await getUserInfo()) != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserInfo);
  }
}
