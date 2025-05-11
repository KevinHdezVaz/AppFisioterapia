import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:LumorahAI/model/User.dart';

class StorageService {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }

  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(tokenKey);

    print("token laravel ${token ?? 'No hay token'}");

    return token;
  }

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        userKey,
        jsonEncode({
          'id': user.id,
          'nombre': user.nombre,
          'email': user.email,
        }));
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(
        userKey); // También eliminamos los datos del usuario al cerrar sesión
  }

  // Nuevos métodos añadidos
  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(userKey);
    if (userJson != null) {
      final userMap = jsonDecode(userJson);
      userMap['nombre'] = name;
      await prefs.setString(userKey, jsonEncode(userMap));
    }
  }

  Future<void> saveNotificationsPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
  }

  Future<bool?> getNotificationsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications');
  }
}
