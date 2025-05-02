import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class DailyTipsMcanager extends ChangeNotifier {
  final List<String> _allTips = [
    'Practica la respiración consciente durante 5 minutos al despertar...',
    'Hidrátate bien durante el día. Intenta tomar al menos 2 litros de agua...',
    // ... (todos tus tips aquí)
  ];

  late List<String> _currentTips;
  final PageController pageController = PageController();
  final Random _random = Random();
  Timer? _autoAdvanceTimer;
  int _currentPage = 0;
  bool _isRandomOrder = true;

  DailyTipsManager() {
    _resetTips();
    _startAutoAdvance();
  }

  void _resetTips() {
    _currentTips = List.from(_allTips);
    if (_isRandomOrder) {
      _currentTips.shuffle(_random);
    }
    _currentPage = 0;
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      nextTip();
    });
  }

  void nextTip() {
    if (_currentPage >= _currentTips.length - 1) {
      _resetTips();
    } else {
      _currentPage++;
    }

    pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }

  void previousTip() {
    _currentPage = (_currentPage - 1).clamp(0, _currentTips.length - 1);
    pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }

  void onPageChanged(int index) {
    _currentPage = index % _currentTips.length;
    notifyListeners();
  }

  String get currentTip => _currentTips[_currentPage];
  int get currentIndex => _currentPage + 1;
  int get totalTips => _allTips.length;
  List<String> get displayedTips => _currentTips;

  void dispose() {
    _autoAdvanceTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }
}
