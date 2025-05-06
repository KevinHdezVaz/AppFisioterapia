import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/model/ChatSession.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class ChatServiceApi {
  final StorageService storage = StorageService();

  Future<dynamic> _authenticatedRequest({
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

      return jsonDecode(responseBody.body); // Devuelve dynamic
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  Future<List<ChatSession>> getSessions() async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: 'chat/sessions',
      );

      debugPrint('Response from getSessions: $response'); // Para depuración

      // Validar que la respuesta sea un Map y tenga el campo 'data'
      if (response is! Map<String, dynamic>) {
        throw FormatException(
            'Se esperaba un Map<String, dynamic>, se obtuvo ${response.runtimeType}');
      }

      if (response['success'] != true) {
        throw Exception(
            'La solicitud falló: ${response['message'] ?? 'Error desconocido'}');
      }

      final sessionsData = response['data'];
      if (sessionsData is! List) {
        throw FormatException(
            'Se esperaba una lista en response["data"], se obtuvo ${sessionsData.runtimeType}');
      }

      return sessionsData.map((json) {
        if (json is Map<String, dynamic>) {
          return ChatSession.fromJson(json);
        } else {
          throw FormatException(
              'Elemento inválido en la lista: se esperaba Map<String, dynamic>, se obtuvo ${json.runtimeType}');
        }
      }).toList();
    } catch (e) {
      debugPrint('Error en getSessions: $e');
      rethrow;
    }
  }

  // Eliminar una sesión
  Future<void> deleteSession(int sessionId) async {
    await _authenticatedRequest(
      method: 'DELETE',
      endpoint: 'chat/sessions/$sessionId',
    );
  }

  // Obtener mensajes de una sesión
  Future<List<Map<String, dynamic>>> getSessionMessages(int sessionId) async {
    final response = await _authenticatedRequest(
      method: 'GET',
      endpoint: 'chat/sessions/$sessionId/messages',
    );

    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    } else {
      throw FormatException(
          'Se esperaba una lista de mensajes, se obtuvo ${response.runtimeType}');
    }
  }

  // Para guardar explícitamente
  Future<void> saveChatSession({
    required String title,
    required List<Map<String, dynamic>> messages,
  }) async {
    await _authenticatedRequest(
      method: 'POST',
      endpoint: 'chat/sessions',
      body: {
        'title': title,
        'messages': messages,
      },
    );
  }

  Future<Map<String, dynamic>> sendMessage(String message) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'chat/send-message', // Endpoint que NO persiste
      body: {'message': message},
    );
    return response;
  }
}
