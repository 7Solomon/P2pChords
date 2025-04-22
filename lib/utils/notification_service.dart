import 'package:flutter/material.dart';

enum SnackType {
  info,
  success,
  error,
  warning,
}

class SnackService {
  static final SnackService _instance = SnackService._internal();
  factory SnackService() => _instance;
  SnackService._internal();

  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  void init(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }

  void show(
    String message, {
    SnackType type = SnackType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_scaffoldMessengerKey?.currentState == null) {
      debugPrint('SnackService: ScaffoldMessengerKey is not initialized');
      return;
    }

    final snackBar = _buildSnackBar(message, type, duration);
    _scaffoldMessengerKey!.currentState!
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }

  SnackBar _buildSnackBar(String message, SnackType type, Duration duration) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData? icon;

    switch (type) {
      case SnackType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case SnackType.error:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case SnackType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case SnackType.info:
      default:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(12),
      duration: duration,
    );
  }

  void showSuccess(String message) => show(message, type: SnackType.success);
  void showError(String message) => show(message, type: SnackType.error);
  void showWarning(String message) => show(message, type: SnackType.warning);
  void showInfo(String message) => show(message, type: SnackType.info);
}
