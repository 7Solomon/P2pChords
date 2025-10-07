import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ConnectionSettings {
  static const _storage = FlutterSecureStorage();
  static const _settingsKey = 'connection_settings';

  String deviceName;
  String? lastRole; // 'hub', 'spoke', or null
  String? lastHubAddress; // For auto-reconnect
  bool autoReconnect;

  ConnectionSettings({
    this.deviceName = 'Mein Gerät',
    this.lastRole,
    this.lastHubAddress,
    this.autoReconnect = false,
  });

  Map<String, dynamic> toJson() => {
    'deviceName': deviceName,
    'lastRole': lastRole,
    'lastHubAddress': lastHubAddress,
    'autoReconnect': autoReconnect,
  };

  factory ConnectionSettings.fromJson(Map<String, dynamic> json) {
    return ConnectionSettings(
      deviceName: json['deviceName'] as String? ?? 'Mein Gerät',
      lastRole: json['lastRole'] as String?,
      lastHubAddress: json['lastHubAddress'] as String?,
      autoReconnect: json['autoReconnect'] as bool? ?? false,
    );
  }

  static Future<ConnectionSettings> load() async {
    try {
      final jsonStr = await _storage.read(key: _settingsKey);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return ConnectionSettings.fromJson(json);
      }
    } catch (e) {
      SnackService().showError('Error loading connection settings: $e');
    }
    return ConnectionSettings();
  }

  Future<void> save() async {
    try {
      final jsonStr = jsonEncode(toJson());
      await _storage.write(key: _settingsKey, value: jsonStr);
    } catch (e) {
      SnackService().showError('Error saving connection settings: $e');
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _settingsKey);
    } catch (e) {
      SnackService().showError('Error clearing connection settings: $e');
    }
  }
}