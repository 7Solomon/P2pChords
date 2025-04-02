import 'dart:async';
import 'dart:typed_data';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';

// Service
class NearbyService extends CustomeService {
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;

  NearbyService._internal() {
    // Initialize empty sets
    connectedDeviceIds = {};
    visibleDevices = {};
    knownDevices = {};
  }

  final Nearby _nearby = Nearby();

  // Vars for managing reconnectoin
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;
  static const Duration _reconnectionInterval = Duration(seconds: 5);

  // For discovery management , Maybe move to CustomeService
  bool _isReconnecting = false;

  // Notification callback for important events
  late String userNickName;
  late Function(String) onNotification;
  late Function(String, Payload) onPayloadReceived;
  late Function(String) addConnectedDevice;

  // Data
  void _notify(String message) {
    onNotification(message);
  }

  // Ovverides
  @override
  Future<bool> startServer() async {
    return await startAdvertising();
  }

  @override
  Future<bool> stopServer() async {
    return await stopAdvertising();
  }

  @override
  Future<bool> startClient() async {
    return await startDiscovery();
  }

  @override
  Future<bool> stopClient() async {
    return await stopDiscovery();
  }

  @override
  Future<bool> connectToServer(String serverId) async {
    return await requestConnection(endpointId: serverId);
  }

  // Start advertising this device so others can find it
  Future<bool> startAdvertising() async {
    try {
      if (isAdvertising) {
        _notify("Already advertising. Stopping current advertising session.");
        await stopAdvertising();
      }

      _notify("Starting advertising as: $userNickName");
      isAdvertising = true;

      bool advertisingResult = await _nearby.startAdvertising(
        userNickName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: (id, info) {
          _notify("Connection initiated with $id (${info.endpointName})");
          _acceptConnection(id);
        },
        onConnectionResult: (id, status) {
          _notify("Connection result for $id: $status");
          if (status == Status.CONNECTED) {
            connectedDeviceIds.add(id);
            knownDevices.add(id);
            // Store device for potential reconnection
            _notify("Successfully connected to $id");
          } else if (status == Status.REJECTED) {
            _notify("Connection rejected by $id");
          } else if (status == Status.ERROR) {
            _notify("Error connecting to $id");
          }

          //if (onConnectionResult != null) {
          //  onConnectionResult(id, status);
          //}
        },
        onDisconnected: (id) {
          _notify("Disconnected from $id");
          connectedDeviceIds.remove(id);

          // Maybe add if statement to check if device was known
          _startReconnection(id);

          //if (onDisconnected != null) {
          //  onDisconnected(id);
          //}
        },
      );

      _notify(advertisingResult
          ? "Successfully started advertising"
          : "Failed to start advertising");

      return advertisingResult;
    } catch (e) {
      isAdvertising = false;
      _notify('Error starting advertising: $e');
      return false;
    }
  }

  // Attempt to reconnect to a device
  void _startReconnection(String endpointId) {
    if (_isReconnecting) return;

    _isReconnecting = true;
    _reconnectionAttempts = 0;

    _notify("Starting reconnection attempts to $endpointId");
    _attemptReconnection(endpointId);
  }

  void _attemptReconnection(String endpointId) {
    if (_reconnectionAttempts >= _maxReconnectionAttempts ||
        connectedDeviceIds.contains(endpointId)) {
      _isReconnecting = false;
      _reconnectionTimer?.cancel();
      _reconnectionTimer = null;
      return;
    }

    _reconnectionAttempts++;
    _notify("Reconnection attempt $_reconnectionAttempts to $endpointId");

    // Try to reconnect
    requestConnection(endpointId: endpointId);

    // Schedule next attempt if needed
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(_reconnectionInterval, () {
      if (!connectedDeviceIds.contains(endpointId)) {
        _attemptReconnection(endpointId);
      }
    });
  }

  // Start discovery to find other devices
  Future<bool> startDiscovery() async {
    try {
      if (isDiscovering) {
        _notify("Already discovering. Stopping current discovery.");
        await stopDiscovery();
      }

      _notify("Starting discovery as: $userNickName");
      isDiscovering = true;

      bool discoveryResult = await _nearby.startDiscovery(
        userNickName,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, serviceId) {
          //_notify("Found endpoint: $id ($name)");
          visibleDevices.add(id);
        },
        onEndpointLost: (id) {
          //_notify("Lost endpoint: $id");
          visibleDevices.remove(id);
        },
      );

      _notify(discoveryResult
          ? "Successfully started discovery"
          : "Failed to start discovery");

      // Set up optional timeout
      //if (timeout != null && discoveryResult) {
      //  Timer(timeout, () {
      //    if (_isDiscovering) {
      //      stopDiscovery();
      //      _notify("Discovery stopped after timeout");
      //    }
      //  });
      //}

      return discoveryResult;
    } catch (e) {
      isDiscovering = false;
      _notify('Error starting discovery: $e');
      return false;
    }
  }

  // Request connection to a discovered endpoint
  Future<bool> requestConnection({required String endpointId}) async {
    try {
      _notify("Requesting connection to $endpointId");

      bool result = await _nearby.requestConnection(
        userNickName,
        endpointId,
        onConnectionInitiated: (id, info) {
          _notify(
              "Connection initiated by request with $id (${info.endpointName})");
          _acceptConnection(id);
        },
        onConnectionResult: (id, status) {
          _notify("Connection result for request to $id: $status");
          if (status == Status.CONNECTED) {
            connectedDeviceIds.add(id);
          } else if (status == Status.REJECTED) {
            _notify("Connection request rejected by $id");
          } else if (status == Status.ERROR) {
            _notify("Error requesting connection to $id");
          }
        },
        onDisconnected: (id) {
          _notify("Disconnected from requested connection $id");
          connectedDeviceIds.remove(id);

          _startReconnection(id);
        },
      );

      return result;
    } catch (e) {
      _notify('Error requesting connection: $e');
      return false;
    }
  }

  // Accept a connection from another device
  void _acceptConnection(String id) {
    _nearby.acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        onPayloadReceived(endid, payload);
      },
    ).catchError((e) {
      _notify("Error accepting connection: $e");
    });
  }

  // Stop advertising
  Future<bool> stopAdvertising() async {
    try {
      await _nearby.stopAdvertising();
      isAdvertising = false;
      return true;
    } catch (e) {
      _notify('Error stopping advertising: $e');
      return false;
    }
  }

  // Stop discovery
  Future<bool> stopDiscovery() async {
    try {
      await _nearby.stopDiscovery();
      isDiscovering = false;
      return true;
    } catch (e) {
      _notify('Error stopping discovery: $e');
      return false;
    }
  }

  // Disconnect from a specific device
  Future<bool> disconnectFromEndpoint(String endpointId) async {
    try {
      await _nearby.disconnectFromEndpoint(endpointId);
      connectedDeviceIds.remove(endpointId);
      knownDevices.remove(
          endpointId); // Remove from known devices to prevent reconnection
      return true;
    } catch (e) {
      _notify('Error disconnecting from endpoint: $e');
      return false;
    }
  }

  // Disconnect from all connected devices
  Future<void> disconnectFromAllEndpoints() async {
    try {
      await _nearby.stopAllEndpoints();
      connectedDeviceIds.clear();
      knownDevices.clear(); // Clear known devices to prevent reconnection
    } catch (e) {
      _notify('Error disconnecting from all endpoints: $e');
    }
  }

  Future<bool> sendBytesPayload(String endpointId, Uint8List bytes) async {
    try {
      await _nearby.sendBytesPayload(endpointId, bytes);
      return true;
    } catch (e) {
      _notify('Error sending bytes payload: $e');
      return false;
    }
  }

  // Clean up resources
  Future<void> dispose() async {
    _reconnectionTimer?.cancel();
    await disconnectFromAllEndpoints();
    await stopAdvertising();
    await stopDiscovery();
  }
}
