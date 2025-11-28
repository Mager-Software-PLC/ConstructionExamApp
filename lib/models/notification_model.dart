import 'package:flutter/foundation.dart';

enum NotificationType {
  message,
  certificate,
  progress,
  achievement,
  system,
  adminAction,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.metadata,
    required this.timestamp,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    NotificationType type;
    switch (json['type'] as String) {
      case 'message':
        type = NotificationType.message;
        break;
      case 'certificate':
        type = NotificationType.certificate;
        break;
      case 'progress':
        type = NotificationType.progress;
        break;
      case 'achievement':
        type = NotificationType.achievement;
        break;
      case 'system':
        type = NotificationType.system;
        break;
      case 'admin_action':
        type = NotificationType.adminAction;
        break;
      default:
        type = NotificationType.system;
    }

    return AppNotification(
      id: json['id'] ?? 'notification-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    String typeString;
    switch (type) {
      case NotificationType.message:
        typeString = 'message';
        break;
      case NotificationType.certificate:
        typeString = 'certificate';
        break;
      case NotificationType.progress:
        typeString = 'progress';
        break;
      case NotificationType.achievement:
        typeString = 'achievement';
        break;
      case NotificationType.system:
        typeString = 'system';
        break;
      case NotificationType.adminAction:
        typeString = 'admin_action';
        break;
    }

    return {
      'id': id,
      'type': typeString,
      'title': title,
      'message': message,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
    };
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }
}

