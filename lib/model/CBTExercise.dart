import 'package:flutter/material.dart';

class CBTExercise {
  final String title;
  final String description;
  final IconData icon;
  final Widget screen; // Ahora almacena el Widget directamente

  const CBTExercise({
    required this.title,
    required this.description,
    required this.icon,
    required this.screen,
  });
}
