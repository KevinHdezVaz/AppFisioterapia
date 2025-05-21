import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:LumorahAI/model/ChatMessage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:LumorahAI/model/ChatSession.dart';
import 'package:LumorahAI/services/storage_service.dart';
import 'package:LumorahAI/utils/constantes.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ChatServiceApi {
  final StorageService storage = StorageService();

  Future<dynamic> _authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final token = await storage.getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse('$baseUrl/$endpoint').replace(
      queryParameters: queryParams != null
          ? {for (var e in queryParams.entries) e.key: e.value.toString()}
          : null,
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[$method] $endpoint - Status: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Sesión expirada, por favor vuelve a iniciar sesión');
      }

      if (response.statusCode >= 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error en la solicitud');
      }

      return jsonDecode(response.body);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  Future<List<ChatSession>> getSessions({bool saved = true}) async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: 'chat/sessions',
        queryParams: {'saved': saved.toString()},
      );

      debugPrint('Response from getSessions: $response');

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

  Future<void> deleteSession(int sessionId) async {
    await _authenticatedRequest(
      method: 'DELETE',
      endpoint: 'chat/sessions/$sessionId',
    );
  }

  Future<List<ChatMessage>> getSessionMessages(int sessionId) async {
    final response = await _authenticatedRequest(
      method: 'GET',
      endpoint: 'chat/sessions/$sessionId/messages',
    );

    if (response is List) {
      return response
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw FormatException(
          'Se esperaba una lista de mensajes, se obtuvo ${response.runtimeType}');
    }
  }

  Future<Map<String, dynamic>> summarizeConversation({
    required List<Map<String, dynamic>> messages,
    required int? sessionId,
    required String language,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'summarize',
      body: {
        'messages': messages,
        'session_id': sessionId,
        'language': language,
      },
    );
    return response;
  }
  
 
Future<void> processAudio(File audioFile) async {
  final token = await storage.getToken();
  if (token == null) throw Exception('No autenticado');

  debugPrint('Token enviado: $token');
  debugPrint('Enviando audio: ${audioFile.path}');

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/chat/process-audio'),
  );
  request.headers['Authorization'] = 'Bearer $token';
  request.headers['Accept'] = 'application/json';
  request.files.add(await http.MultipartFile.fromPath(
    'audio',
    audioFile.path,
    contentType: MediaType('audio', 'mp4'),
  ));

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  debugPrint('Status Code: ${response.statusCode}');
  debugPrint('Response Body: ${response.body}');
  debugPrint('Headers: ${response.headers}');

  if (response.statusCode != 200) {
    throw Exception('Error al procesar audio: ${response.body}');
  }
}

  Future<ChatSession> saveChatSession({
    required String title,
    required List<Map<String, dynamic>> messages,
    int? sessionId,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'chat/sessions',
      body: {
        'title': title,
        'messages': messages,
        if (sessionId != null) 'session_id': sessionId,
      },
    );

    if (response is Map<String, dynamic> && response['success'] == true) {
      return ChatSession.fromJson(response['data']);
    } else {
      throw Exception('Error al guardar la sesión');
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    int? sessionId,
    bool isTemporary = false,
    required String language,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'chat/send-message',
      body: {
        'message': message,
        'session_id': sessionId,
        'is_temporary': isTemporary,
        'language': language,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> sendTemporaryMessage(
    String message, {
    required String language,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'chat/send-temporary-message',
      body: {
        'message': message,
        'language': language,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> startNewSession({
    required String language,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: 'chat/start-new-session',
      body: {'language': language},
    );
    return response;
  }

  Future<void> updateUserName(String name, {required String language}) async {
    await _authenticatedRequest(
      method: 'POST',
      endpoint: 'update-name',
      body: {'name': name, 'language': language},
    );
  }

  Future<void> saveSession(int sessionId, String title) async {
    await _authenticatedRequest(
      method: 'PUT',
      endpoint: 'chat/sessions/$sessionId',
      body: {'title': title},
    );
  }
}