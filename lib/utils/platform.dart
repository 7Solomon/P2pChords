import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility class for platform detection
class PlatformUtils {
  /// Check if the current platform is a mobile device
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Check if the current platform is a desktop
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Check if the current platform is web
  static bool get isWeb => kIsWeb;

  /// Check if the current platform should use WebSocket connections
  static bool get shouldUseWebSockets => isDesktop || isWeb;

  /// Check if the current platform should use Nearby Connections
  static bool get shouldUseNearbyConnections => isMobile;
}
