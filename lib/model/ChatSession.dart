import 'package:flutter/material.dart';

class ChatSession {
  final int id;
  final int userId;
  final String title;
  final bool isSaved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    this.isSaved = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    try {
      return ChatSession(
        id: _parseInt(json['id']),
        userId: _parseInt(json['user_id']),
        title: _parseString(json['title']),
        isSaved: _parseBool(json['is_saved']),
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
        deletedAt: json['deleted_at'] != null
            ? _parseDateTime(json['deleted_at'])
            : null,
      );
    } catch (e) {
      throw FormatException('Error parsing ChatSession: $e');
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'is_saved': isSaved,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  // Helpers para parseo seguro
  static int _parseInt(dynamic value) {
    if (value == null) throw ArgumentError('Expected integer, got null');
    return value is int ? value : int.tryParse(value.toString()) ?? 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) throw ArgumentError('Expected string, got null');
    return value.toString();
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) throw ArgumentError('Expected date string, got null');
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      throw FormatException('Invalid date format: $value');
    }
  }

  // Método para copiar con cambios
  ChatSession copyWith({
    int? id,
    int? userId,
    String? title,
    bool? isSaved,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode;

  @override
  String toString() {
    return 'ChatSession{id: $id, userId: $userId, title: $title, '
        'isSaved: $isSaved, createdAt: $createdAt, '
        'updatedAt: $updatedAt, deletedAt: $deletedAt}';
  }
}
