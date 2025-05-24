import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility class for platform detection
class PlatformUtils {
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Check if the current platorm is web
  static bool get isWeb => kIsWeb;

  static bool get shouldUseWebSockets => isDesktop || isWeb;
  static bool get shouldUseNearbyConnections => isMobile;
  static bool get supportsHeadlessWebView => isMobile;
}
