import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:LumorahAI/model/User.dart';
import 'dart:convert';
import 'package:LumorahAI/services/storage_service.dart';
import 'package:LumorahAI/utils/constantes.dart';

class AuthService {
  final storage = StorageService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId:
        '709069828022-dl6ee03rv72hbshc7d99jdfrpk993j8b.apps.googleusercontent.com', // ID de iOS (de GoogleService-Info.plist)
    serverClientId:
        '709069828022-8kvhc185ue5e20u88eofmv6cfcp0mua3.apps.googleusercontent.com', // ID de web/Android
  );

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? postalCode,
    String? posicion,
    File? profileImage,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/profile');

      Map<String, String> fields = {};
      if (name != null) fields['name'] = name;
      if (phone != null) fields['phone'] = phone;
      if (postalCode != null) fields['codigo_postal'] = postalCode;
      if (posicion != null) fields['posicion'] = posicion;

      final headers = await getHeaders();

      if (profileImage != null) {
        final request = http.MultipartRequest('POST', uri)
          ..headers.addAll(headers)
          ..fields.addAll(fields);

        final fileStream = http.ByteStream(profileImage.openRead());
        final length = await profileImage.length();
        final multipartFile = http.MultipartFile(
          'profile_image',
          fileStream,
          length,
          filename: profileImage.path.split('/').last,
        );
        request.files.add(multipartFile);

        request.fields['_method'] = 'PUT';

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print('Respuesta: ${response.body}');
        return response.statusCode == 200;
      } else {
        final response = await http.put(
          uri,
          headers: headers,
          body: json.encode(fields),
        );

        print('Respuesta: ${response.body}');
        return response.statusCode == 200;
      }
    } catch (e) {
      print('Error actualizando perfil: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password,
      {double? latitude, double? longitude}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['token'] != null) {
        await storage.saveToken(data['token']);
        print('Token saved: ${data['token']}');
        if (data['user'] != null) {
          final user = User.fromJson(data['user']);
          print('User parsed: ${user.toJson()}');
          await storage.saveUser(user);
          print('User saved to storage');
          if (data['user']['id'] != null) {
            await saveUserId(data['user']['id']);
            print('User ID saved: ${data['user']['id']}');
          }
        } else {
          print('No user data in response');
        }
        return true;
      }
      print('No token in response');
      return false;
    } catch (e) {
      print('Error login: $e');
      return false;
    }
  }

  Future<bool> loginWithGoogle(String? idToken) async {
    if (idToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/google-login'), // Ajustado al endpoint correcto
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_token': idToken}),
      );

      print('Google login response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }

      final data = json.decode(response.body);
      if (data['token'] != null) {
        await storage.saveToken(data['token']);
        if (data['user'] != null) {
          final user = User.fromJson(data['user']);
          await storage.saveUser(user);
          if (data['user']['id'] != null) {
            await saveUserId(data['user']['id']);
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error en loginWithGoogle: $e');
      throw Exception('Error en Google Sign-In: $e');
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      // 1. Iniciar el flujo de autenticación con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      // 2. Obtener los tokens de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('idToken generado: ${googleAuth.idToken}');

      // 3. Verificar que tenemos el idToken
      if (googleAuth.idToken == null) {
        throw Exception('No se pudo obtener el ID token de Google');
      }

      // 4. Enviar el token a tu backend Laravel
      return await loginWithGoogle(googleAuth.idToken!);
    } catch (e) {
      print('Error en Google Sign-In: $e');
      return false;
    }
  }

  Future<void> updateDeviceToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-device-token'),
        headers: await getHeaders(),
        body: json.encode({'device_token': token}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error actualizando token');
      }
    } catch (e) {
      print('Error: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: await getHeaders(),
      );

      print('Profile response: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Error obteniendo perfil');
      }

      final data = json.decode(response.body);
      print('Profile data: $data');
      return data;
    } catch (e) {
      print('Error getting profile: $e');
      throw Exception('Error: $e');
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await getHeaders(),
      );
      await storage.removeToken();
    } catch (e) {
      throw Exception('Error al cerrar sesión');
    }
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      return json.decode(response.body)['exists'];
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkPhoneExists(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check-phone'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone}),
      );
      return json.decode(response.body)['exists'];
    } catch (e) {
      return false;
    }
  }

  Future<int?> getCurrentUserId() async {
    try {
      final profileData = await getProfile();
      return profileData['id'];
    } catch (e) {
      print('Error obteniendo ID del usuario: $e');
      return null;
    }
  }

  Future<void> saveUserId(int id) async {
    // await storage.saveString('user_id', id.toString());
  }

  Future<int?> getUserIdFromStorage() async {
    // final idStr = await storage.getString('user_id');
    // return idStr != null ? int.parse(idStr) : null;
    return null;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nombre': name,
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Register response status: ${response.statusCode}');
      debugPrint('Register response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (data['token'] == null || data['user'] == null) {
          throw Exception('El servidor no devolvió todos los datos necesarios');
        }

        final token = data['token'].toString();
        if (token.isEmpty) {
          throw Exception('Token vacío recibido del servidor');
        }

        await storage.saveToken(token);
        print('Register token saved: $token');

        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        await storage.saveUser(user);
        print('Register user saved: ${user.toJson()}');

        return true;
      } else {
        final errorMsg = data['message'] ?? 'Error desconocido';
        throw Exception('Error del servidor: $errorMsg');
      }
    } catch (e) {
      debugPrint('Error en register: $e');
      throw Exception('Error en el registro: ${e.toString()}');
    }
  }
}
