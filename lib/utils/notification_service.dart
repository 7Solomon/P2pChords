import 'dart:async';

import 'package:flutter/material.dart';

enum NotificationLevel { info, warning, error, success }

class AppNotification {
  final String message;
  final NotificationLevel level;
  final DateTime timestamp;
  final String? source;

  AppNotification({
    required this.message,
    this.level = NotificationLevel.info,
    required this.timestamp,
    this.source,
  });
}

class NotificationService extends ChangeNotifier {
  // Recent notifications
  final List<AppNotification> _notifications = [];

  // Callbacks
  final List<Function(AppNotification)> _listeners = [];

  // Get recent notifications
  List<AppNotification> get recentNotifications =>
      List.unmodifiable(_notifications);

  // Add notification
  void notify({
    required String message,
    NotificationLevel level = NotificationLevel.info,
    String? source,
  }) {
    final notification = AppNotification(
      message: message,
      level: level,
      timestamp: DateTime.now(),
      source: source,
    );

    _notifications.add(notification);

    // Keep only the 50 most recent notifications
    if (_notifications.length > 50) {
      _notifications.removeAt(0);
    }

    // Notify listeners
    for (var listener in _listeners) {
      listener(notification);
    }

    notifyListeners();
  }

  // Add notification listener
  void addNotificationListener(Function(AppNotification) listener) {
    _listeners.add(listener);
  }

  // Remove notification listener
  void removeNotificationListener(Function(AppNotification) listener) {
    _listeners.remove(listener);
  }

  // Clear notifications
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
