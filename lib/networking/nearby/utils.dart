import 'dart:async';

class Reconnection {
  final Function requestConnection;
  final Set<String> connectedDeviceIds;
  final Set<String> knownDevices;

  Reconnection({
    required this.requestConnection,
    required this.connectedDeviceIds,
    required this.knownDevices,
  });
  // Vars for managing reconnectoin
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;
  static const Duration _reconnectionInterval = Duration(seconds: 5);

  // For discovery management , Maybe move to CustomeService
  bool _isReconnecting = false;

  // Attempt to reconnect to a device
  void startReconnection(String endpointId) {
    if (_isReconnecting || !knownDevices.contains(endpointId)) {
      return;
    } // Only reconnect known devices

    _isReconnecting = true;
    _reconnectionAttempts = 0;

    // _log("Starting reconnection attempts to $endpointId");
    _attemptReconnection(endpointId);
  }

  void _attemptReconnection(String endpointId) {
    if (!knownDevices.contains(endpointId)) {
      // Stop if device was explicitly disconnected
      _isReconnecting = false;
      _reconnectionTimer?.cancel();
      _reconnectionTimer = null;
      return;
    }

    if (_reconnectionAttempts >= _maxReconnectionAttempts ||
        connectedDeviceIds.contains(endpointId)) {
      _isReconnecting = false;
      _reconnectionTimer?.cancel();
      _reconnectionTimer = null;
      return;
    }

    _reconnectionAttempts++;

    // Try to reconnect
    requestConnection(endpointId: endpointId);

    // Schedule next attempt
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(_reconnectionInterval, () {
      if (knownDevices.contains(endpointId) &&
          !connectedDeviceIds.contains(endpointId)) {
        _attemptReconnection(endpointId);
      } else {
        _isReconnecting = false; // Stop if connected or no longer known
      }
    });
  }

  Future<void> dispose() async {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
  }
}
