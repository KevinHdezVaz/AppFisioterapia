import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class ChatServiceApi {
  final StorageService storage = StorageService();

// Ejemplo aplicable a todos los métodos
  Future<List<dynamic>> getSessions() async {
    try {
      final token = await storage.getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.get(
        Uri.parse('$baseUrl/chat/sessions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        throw Exception('Sesión expirada, por favor vuelve a iniciar sesión');
      }

      if (response.statusCode != 200) {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }

      return jsonDecode(response.body);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al obtener sesiones');
    } catch (e) {
      throw Exception('Error al obtener sesiones: ${e.toString()}');
    }
  }

// En tu ChatServiceApi.dart
  Future<void> deleteSession(int sessionId) async {
    try {
      final token = await storage.getToken();
      if (token == null) {
        throw Exception('No se encontró el token de autenticación');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/chat/sessions/$sessionId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar sesión: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener los mensajes de una sesión específica
  Future<List<dynamic>> getSessionMessages(int sessionId) async {
    try {
      final token = await storage.getToken();
      if (token == null) {
        throw Exception('No se encontró el token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/chat/sessions/$sessionId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('GetSessionMessages Response status: ${response.statusCode}');
      debugPrint('GetSessionMessages Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener mensajes: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> saveChatSession(int? sessionId, String title,
      {bool isSaved = true}) async {
    try {
      final token = await storage.getToken();
      if (token == null) throw Exception('No autenticado');

      // Determinar si es creación o actualización
      final isUpdate = sessionId != null && sessionId > 0;
      final method = isUpdate ? 'PUT' : 'POST';
      final url = isUpdate
          ? '$baseUrl/chat/sessions/$sessionId'
          : '$baseUrl/chat/sessions';

      final response = await http.Request(method, Uri.parse(url))
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        })
        ..body = jsonEncode({
          'title': title,
          'is_saved': isSaved,
        });

      final streamedResponse =
          await response.send().timeout(const Duration(seconds: 10));
      final responseBody = await http.Response.fromStream(streamedResponse);

      if (responseBody.statusCode == 404) {
        throw Exception('Sesión no encontrada');
      }

      if (responseBody.statusCode == 422) {
        final errors = jsonDecode(responseBody.body)?['errors'] ?? {};
        throw Exception('Error de validación: ${errors.values.join(', ')}');
      }

      if (responseBody.statusCode != 200 && responseBody.statusCode != 201) {
        throw Exception(
            'Error ${responseBody.statusCode}: ${responseBody.body}');
      }

      return jsonDecode(responseBody.body);
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: ${e.message}');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Enviar un mensaje y recibir la respuesta de la IA
  Future<Map<String, dynamic>> sendMessage(String message,
      {int? sessionId}) async {
    try {
      final token = await storage.getToken();
      if (token == null) {
        throw Exception('No se encontró el token de autenticación');
      }

      final response = await http.post(
        Uri.parse(
            '$baseUrl/chat/send-message'), // Asegúrate que coincide con tu ruta en el backend
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
        }),
      );

      debugPrint('SendMessage Response status: ${response.statusCode}');
      debugPrint('SendMessage Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al enviar mensaje: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
