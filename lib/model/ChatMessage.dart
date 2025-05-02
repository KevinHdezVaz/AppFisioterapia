import 'package:flutter/material.dart';

class ChatMessage {
  final int id;
  final int chatSessionId;
  final int userId;
  final String text;
  final bool isUser;
  final String? imageUrl; // Nuevo campo para la imagen
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessage({
    required this.id,
    required this.chatSessionId,
    required this.userId,
    required this.text,
    required this.isUser,
    this.imageUrl, // Opcional
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: int.parse(json['id'].toString()),
      chatSessionId: int.parse(json['chat_session_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      text: json['text'] as String,
      isUser: (json['is_user'] as int) == 1,
      imageUrl: json['image_url'] as String?, // Nuevo campo en el JSON
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_session_id': chatSessionId,
      'user_id': userId,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'image_url': imageUrl, // Nuevo campo en el JSON
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
