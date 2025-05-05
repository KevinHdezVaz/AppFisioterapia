import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class ChatServiceApi {
  final StorageService storage = StorageService();

  Future<Map<String, dynamic>> _authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final token = await storage.getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.Request(method, uri)
        ..headers.addAll(headers)
        ..body = body != null ? jsonEncode(body) : '';

      final streamedResponse =
          await response.send().timeout(const Duration(seconds: 10));
      final responseBody = await http.Response.fromStream(streamedResponse);

      debugPrint('[$method] $endpoint - Status: ${responseBody.statusCode}');
      debugPrint('Response: ${responseBody.body}');

      if (responseBody.statusCode == 401) {
        throw Exception('Sesión expirada, por favor vuelve a iniciar sesión');
      }

      if (responseBody.statusCode >= 400) {
        final errorData = jsonDecode(responseBody.body);
        throw Exception(errorData['message'] ?? 'Error en la solicitud');
      }

      return jsonDecode(responseBody.body);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  // Obtener todas las sesiones guardadas
  Future<List<dynamic>> getSessions() async {
    final response = await _authenticatedRequest(
      method: 'GET',
      endpoint: 'chat/sessions',
    );
    return response['data'] ?? [];
  }

  // Eliminar una sesión
  Future<void> deleteSession(int sessionId) async {
    await _authenticatedRequest(
      method: 'DELETE',
      endpoint: 'chat/sessions/$sessionId',
    );
  }

  // Obtener mensajes de una sesión
  Future<List<dynamic>> getSessionMessages(int sessionId) async {
    final response = await _authenticatedRequest(
      method: 'GET',
      endpoint: 'chat/sessions/$sessionId/messages',
    );
    return response['data'] ?? [];
  }

  // Guardar una nueva sesión (solo se llama cuando el usuario hace clic en guardar)
  Future<Map<String, dynamic>> saveChatSession({
    required String title,
    required List<Map<String, dynamic>> messages,
  }) async {
    return await _authenticatedRequest(
      method: 'POST',
      endpoint: 'chat/sessions',
      body: {
        'title': title,
        'messages': messages,
      },
    );
  }

  // Enviar mensaje sin crear sesión persistente
  Future<Map<String, dynamic>> sendMessage(String message) async {
    return await _authenticatedRequest(
      method: 'POST',
      endpoint: 'chat/send-message',
      body: {'message': message},
    );
  }
}
