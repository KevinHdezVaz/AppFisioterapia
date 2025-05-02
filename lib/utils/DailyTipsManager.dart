import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class DailyTipsManager extends ChangeNotifier {
  final List<String> _allTips = [
    'Practica la respiración consciente durante 5 minutos al despertar. Inhala profundamente por 4 segundos, mantén por 7 y exhala por 8.',
    'Hidrátate bien durante el día. Intenta tomar al menos 2 litros de agua para mantener tu cuerpo y mente en óptimas condiciones.',
    'Realiza pausas activas cada hora si trabajas sentado. Levántate, estírate y camina unos minutos.',
    'Dedica 10 minutos al día a meditar. Esto ayudará a reducir el estrés y mejorar tu concentración.',
    'Anota 3 cosas por las que estés agradecido cada día. Este simple ejercicio mejora el bienestar emocional.',
    'Camina al menos 30 minutos diarios. El movimiento regular mejora la circulación y el estado de ánimo.',
    'Evita las pantallas al menos 1 hora antes de dormir para mejorar la calidad de tu sueño.',
    'Incluye vegetales de diferentes colores en cada comida para obtener una variedad de nutrientes.',
    'Practica la regla del 20-20-20 para descansar tus ojos: cada 20 minutos, mira algo a 20 pies (6m) por 20 segundos.',
    'Organiza tu espacio de trabajo cada noche para comenzar el día siguiente con orden y claridad mental.',
    'Aprende algo nuevo cada día, aunque sea pequeño. Mantiene tu mente activa y en crecimiento.',
    'Sonríe intencionalmente varias veces al día. Esto puede mejorar tu estado de ánimo y reducir el estrés.',
  ];

  late List<String> _currentTips;
  final PageController pageController = PageController();
  final Random _random = Random();
  Timer? _autoAdvanceTimer;
  int _currentPage = 0;

  DailyTipsManager() {
    _resetTips();
    startAutoAdvance();
  }

  void _resetTips() {
    _currentTips = List.from(_allTips);
    _currentTips.shuffle(_random);
    _currentPage = 0;
  }

  void startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      nextTip();
    });
  }

  // Igual para stopAutoAdvance
  void stopAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
  }

  void nextTip() {
    if (!pageController.hasClients) return; // Verificación crucial

    if (_currentPage >= _currentTips.length - 1) {
      _resetTips();
    } else {
      _currentPage++;
    }

    pageController
        .animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    )
        .then((_) {
      notifyListeners();
    });
  }

  void previousTip() {
    if (!pageController.hasClients) return; // Verificación crucial

    _currentPage = (_currentPage - 1).clamp(0, _currentTips.length - 1);
    pageController
        .animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    )
        .then((_) {
      notifyListeners();
    });
  }

  void onPageChanged(int index) {
    if (!pageController.hasClients) return; // Verificación crucial

    _currentPage = index % _currentTips.length;
    notifyListeners();
  }

  String get currentTip => _currentTips[_currentPage];
  int get currentIndex => _currentPage + 1;
  int get totalTips => _allTips.length;
  List<String> get displayedTips => _currentTips;

  @override
  void dispose() {
    // Primero cancela el timer
    _autoAdvanceTimer?.cancel();

    // Luego elimina los listeners
    pageController.removeListener(() {});

    // Finalmente elimina el controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.dispose();
      }
    });

    super.dispose();
  }
}
