import 'package:flutter/material.dart';

class ChatMessage {
  final int id;
  final int chatSessionId;
  final int userId;
  final String text;
  final bool isUser;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? emotionalState; // Nuevo campo para el estado emocional
  final String? conversationLevel; // Nuevo campo para el nivel de conversación

  ChatMessage({
    required this.id,
    required this.chatSessionId,
    required this.userId,
    required this.text,
    required this.isUser,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.emotionalState, // Opcional
    this.conversationLevel, // Opcional
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: int.parse(json['id'].toString()),
      chatSessionId: int.parse(json['chat_session_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      text: json['text'] as String,
      isUser: (json['is_user'] as int) == 1,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      emotionalState: json['emotional_state'] as String?, // Nuevo campo
      conversationLevel: json['conversation_level'] as String?, // Nuevo campo
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_session_id': chatSessionId,
      'user_id': userId,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'emotional_state': emotionalState, // Nuevo campo
      'conversation_level': conversationLevel, // Nuevo campo
    };
  }
}