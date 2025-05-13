import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:easy_localization/easy_localization.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isSpeechInitialized = false;
  String _transcribedText = '';
  bool _isUsingVoiceInput = false;

  // Mapa de códigos de idioma para reconocimiento de voz
  final Map<String, String> _speechLocales = {
    'es': 'es_ES',
    'en': 'en_US',
    'fr': 'fr_FR',
    'pt': 'pt_BR',
  };

  // Getter para el estado de escucha
  bool get isListening => _isListening;

  // Getter para el texto transcrito
  String get transcribedText => _transcribedText;

  // Getter para verificar si se usó entrada de voz
  bool get isUsingVoiceInput => _isUsingVoiceInput;

  VoiceService() {
    _setupTts();
  }

  // Configurar el motor de TTS
  Future<void> _setupTts() async {
    await _flutterTts.setLanguage('es-ES'); // Idioma por defecto
    await _flutterTts.setSpeechRate(0.5); // Velocidad (0.0 a 1.0)
    await _flutterTts.setVolume(1.0); // Volumen (0.0 a 1.0)
    await _flutterTts.setPitch(1.0); // Tono (0.5 a 2.0)

    _flutterTts.setStartHandler(() {
      debugPrint("TTS: Reproducción iniciada");
    });
    _flutterTts.setCompletionHandler(() {
      debugPrint("TTS: Reproducción completada");
    });
    _flutterTts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
    });
  }

  // Actualizar el idioma de TTS según el idioma de la app
  Future<void> updateTtsLanguage(String languageCode) async {
    final ttsLanguage = _getTtsLanguage(languageCode);
    await _flutterTts.setLanguage(ttsLanguage);
  }

  // Mapear el idioma de la app al idioma de TTS
  String _getTtsLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'en-US';
      case 'fr':
        return 'fr-FR';
      case 'pt':
        return 'pt-BR';
      default:
        return 'es-ES';
    }
  }

  // Iniciar el reconocimiento de voz
  Future<void> startListening({
    required String languageCode,
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    if (_isListening) {
      debugPrint('Reconocimiento de voz ya está activo, ignorando nueva solicitud.');
      return;
    }

    bool available = _isSpeechInitialized;
    if (!_isSpeechInitialized) {
      available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );
      if (available) {
        _isSpeechInitialized = true;
      }
    }

    if (available) {
      _isListening = true;
      _isUsingVoiceInput = true;
      Timer? silenceTimer;
      final localeId = _speechLocales[languageCode] ?? 'es_ES';
      _speech.listen(
        onResult: (result) {
          _transcribedText = result.recognizedWords;
          onResult(_transcribedText);
          silenceTimer?.cancel();
          silenceTimer = Timer(Duration(seconds: 3), () {
            if (_transcribedText.isNotEmpty) {
              stopListening();
            }
          });
        },
        localeId: localeId,
        pauseFor: Duration(seconds: 3),
      );
    } else {
      onError('speechNotInitialized'.tr());
    }
  }

  // Detener el reconocimiento de voz
  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _speech.cancel();
    }
    _isListening = false;
  }

  // Reproducir texto como voz
  Future<void> speak(String text, {String? emotionalState}) async {
    if (text.isEmpty) return;

    // Ajustar la voz según el estado emocional
    if (emotionalState == 'sensitive') {
      await _flutterTts.setSpeechRate(0.4); // Más lento
      await _flutterTts.setPitch(0.9); // Tono más suave
    } else if (emotionalState == 'crisis') {
      await _flutterTts.setSpeechRate(0.45); // Lento y calmado
      await _flutterTts.setPitch(0.85); // Tono más grave
    } else {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
    }

    await _flutterTts.speak(text);
  }

  // Detener la reproducción de voz
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  // Limpiar recursos
  void dispose() {
    _speech.stop();
    _speech.cancel();
    _flutterTts.stop();
  }
}