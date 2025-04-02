import 'dart:async';
import 'package:flutter/material.dart';

enum NotificationType { info, success, warning, error }

class NotificationMessage {
  final String message;
  final NotificationType type;

  NotificationMessage(this.message, this.type);
}

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Stream controller for notifications
  final _notificationController =
      StreamController<NotificationMessage>.broadcast();

  // Public stream that UI components can listen to
  Stream<NotificationMessage> get notifications =>
      _notificationController.stream;

  // Methods for different notification types
  void showInfo(String message) {
    _notify(NotificationMessage(message, NotificationType.info));
  }

  void showSuccess(String message) {
    _notify(NotificationMessage(message, NotificationType.success));
  }

  void showWarning(String message) {
    _notify(NotificationMessage(message, NotificationType.warning));
  }

  void showError(String message) {
    _notify(NotificationMessage(message, NotificationType.error));
  }

  // Internal method to send notification
  void _notify(NotificationMessage notification) {
    _notificationController.add(notification);
  }

  // Clean up resources
  void dispose() {
    _notificationController.close();
  }
}
