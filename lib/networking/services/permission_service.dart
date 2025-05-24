import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';

class PermissionService {
  // Singleton pattern
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;

  final NotificationService _notificationService = NotificationService();

  PermissionService._internal();

  // List of required permissions for the app
  List<Permission> get _requiredPermissions {
    if (kIsWeb) {
      // For web, most of these permissions are not applicable
      // or are handled differently by the browser.
      // If you were using Permission.location and permission_handler supports it for web,
      // you could include it here. Otherwise, an empty list is appropriate.
      return [];
    } else {
      // Original mobile permissions
      return [
        Permission.location,
        Permission.bluetooth,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.nearbyWifiDevices,
      ];
    }
  }

  // Request all required permissions with optional callback for notifications
  Future<bool> requestPermissions({Function(String)? onMessage}) async {
    final currentPlatformPermissions = _requiredPermissions;

    if (currentPlatformPermissions.isEmpty) {
      const message = kIsWeb
          ? "Permissions on web are managed by the browser or are not applicable for this app's features."
          : "No permissions configured to request.";
      if (onMessage != null) {
        onMessage(message);
      } else {
        _notificationService.showInfo(message);
      }
      return true;
    }

    final statuses = await currentPlatformPermissions.request();
    final allGranted = statuses.values.every((status) => status.isGranted);
    final message =
        allGranted ? "All permissions granted" : "Some permissions were denied";

    if (onMessage != null) {
      onMessage(message);
    } else {
      if (allGranted) {
        _notificationService.showSuccess(message);
      } else {
        _notificationService.showWarning(message);
      }
    }
    return allGranted;
  }

  Future<bool> checkPermissionStatus() async {
    final currentPlatformPermissions = _requiredPermissions;

    if (currentPlatformPermissions.isEmpty) {
      return true;
    }

    Map<Permission, PermissionStatus> statuses = {};
    for (var permission in currentPlatformPermissions) {
      statuses[permission] = await permission.status;
    }
    return statuses.values.every((status) => status.isGranted);
  }

  // Check specific permission status
  Future<PermissionStatus> getPermissionStatus(Permission permission) async {
    if (kIsWeb) {
      final webPermissions = _requiredPermissions;
      if (!webPermissions.contains(permission)) {
        return PermissionStatus.denied;
      }
    }
    return await permission.status;
  }
}
