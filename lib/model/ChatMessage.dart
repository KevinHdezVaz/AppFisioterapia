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
  final String? emotionalState;
  final String? conversationLevel;

  ChatMessage({
    required this.id,
    required this.chatSessionId,
    required this.userId,
    required this.text,
    required this.isUser,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.emotionalState,
    this.conversationLevel,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: int.tryParse(json['id'].toString()) ?? -1,
      chatSessionId: int.tryParse(json['chat_session_id'].toString()) ?? -1,
      userId: int.tryParse(json['user_id'].toString()) ?? -1,
      text: json['text'] as String? ?? '',
      isUser: json['is_user'] is bool
          ? json['is_user']
          : (json['is_user'] == 1 || json['is_user'].toString() == 'true'),
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      emotionalState: json['emotional_state'] as String?,
      conversationLevel: json['conversation_level'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_session_id': chatSessionId,
      'user_id': userId,
      'text': text,
      'is_user': isUser,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'emotional_state': emotionalState,
      'conversation_level': conversationLevel,
    };
  }
}
