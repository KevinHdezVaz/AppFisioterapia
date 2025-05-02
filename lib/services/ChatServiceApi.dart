import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class ChatServiceApi {
  final StorageService storage = StorageService();

  /// Obtener todas las sesiones de chat del usuario autenticado
  Future<List<dynamic>> getSessions() async {
    try {
      final token = await storage.getToken();
      if (token == null) {
        throw Exception('No se encontró el token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/chat/sessions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('GetSessions Response status: ${response.statusCode}');
      debugPrint('GetSessions Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener sesiones: ${response.body}');
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

  /// Enviar un mensaje y recibir la respuesta de la IA
  Future<Map<String, dynamic>> sendMessage(String message,
      {int? sessionId}) async {
    try {
      final token = await storage.getToken();
      if (token == null) {
        throw Exception('No se encontró el token de autenticación');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/send'),
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
