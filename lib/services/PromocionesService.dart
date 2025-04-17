import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/Promocion.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'package:http/http.dart' as http;

class PromocionService {
  final StorageService storage = StorageService();

  Future<List<Promocion>> fetchPromociones() async {
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/promociones'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Promociones Response status: ${response.statusCode}');
      debugPrint('Promociones Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Promocion.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar promociones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
