import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/Premio.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'package:http/http.dart' as http;

class PremioService {
  final StorageService storage = StorageService();

  Future<List<Premio>> fetchPremios() async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/premios'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Premios Response status: ${response.statusCode}');
      debugPrint('Premios Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Premio.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar premios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
