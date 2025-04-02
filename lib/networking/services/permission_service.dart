import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';

class PermissionService {
  // Singleton pattern
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;

  final NotificationService _notificationService = NotificationService();

  PermissionService._internal();

  // List of required permissions for the app
  List<Permission> get _requiredPermissions => [
        Permission.location,
        Permission.bluetooth,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.nearbyWifiDevices,
      ];

  // Request all required permissions with optional callback for notifications
  Future<bool> requestPermissions({Function(String)? onMessage}) async {
    final statuses = await _requiredPermissions.request();

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

  // Check if all permissions are granted without requesting
  Future<bool> checkPermissionStatus() async {
    Map<Permission, PermissionStatus> statuses = {};
    for (var permission in _requiredPermissions) {
      statuses[permission] = await permission.status;
    }

    return statuses.values.every((status) => status.isGranted);
  }

  // Check specific permission status
  Future<PermissionStatus> getPermissionStatus(Permission permission) async {
    return await permission.status;
  }
}
