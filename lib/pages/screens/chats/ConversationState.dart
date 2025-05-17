import 'package:LumorahAI/model/ChatMessage.dart';
 import 'package:flutter/material.dart';

class ConversationState with ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isRecording = false;
  bool _isThinking = false;
  String _currentMessage = '';
  String? _currentAudioPath;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isListening => _isListening;
  bool get isRecording => _isRecording;
  bool get isThinking => _isThinking;
  String get currentMessage => _currentMessage;
  String? get currentAudioPath => _currentAudioPath;

  void setIsListening(bool value) {
    _isListening = value;
    notifyListeners();
  }

  void setIsRecording(bool value) {
    _isRecording = value;
    notifyListeners();
  }

  void setIsThinking(bool value) {
    _isThinking = value;
    notifyListeners();
  }

  void setCurrentMessage(String message) {
    _currentMessage = message;
    notifyListeners();
  }

  void setCurrentAudioPath(String? path) {
    _currentAudioPath = path;
    notifyListeners();
  }

  void addUserMessage(String text, {String? emotionalState}) {
    final message = ChatMessage(
      id: -1,
      chatSessionId: -1, // No usamos sesiones
      userId: 0,
      text: text,
      isUser: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      emotionalState: emotionalState ?? 'neutral',
      conversationLevel: 'basic',
    );
    _messages.insert(0, message);
    notifyListeners();
  }

  void addAiMessage(String text, {String? emotionalState, String? conversationLevel}) {
    final message = ChatMessage(
      id: -1,
      chatSessionId: -1, // No usamos sesiones
      userId: null,
      text: text,
      isUser: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      emotionalState: emotionalState ?? 'neutral',
      conversationLevel: conversationLevel ?? 'basic',
    );
    _messages.insert(0, message);
    notifyListeners();
  }

  void clearConversation() {
    _messages.clear();
    _currentMessage = '';
    _currentAudioPath = null;
    notifyListeners();
  }
}