import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_auth_crudd10/model/User.dart';

class StorageService {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
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
          'saldo_puntos': user.saldoPuntos,
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
}
