import 'package:flutter/material.dart';

class LumorahColors {
  // Nuevo color principal (#40ac9f)
  static const Color primary = Color(0xFF40AC9F);

  // Variaciones del color principal
  static const Color primaryLight = Color(0xFF6BC4B9);
  static const Color primaryLighter = Color(0xFF9BDDD5);
  static const Color primaryDark = Color(0xFF2A8C80);
  static const Color primaryDarker = Color(0xFF1A6D63);

  // Colores complementarios
  static const Color secondary = Color(0xFFAC4070); // Complementario análogo
  static const Color accent = Color(0xFFAC8440); // Color de acento

  // Colores neutrales
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFF333333);
  static const Color textDark = Color(0xFFE0E0E0);

  // Colores para estados
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Degradado basado en el color principal
  static Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  // Método alternativo para crear el color si necesitas valores RGB entre 0 y 1
  static Color fromRGB(
      {double red = 0, double green = 0, double blue = 0, double alpha = 1}) {
    return Color.fromRGBO(
      (red * 255).round(),
      (green * 255).round(),
      (blue * 255).round(),
      alpha,
    );
  }
}
