import 'dart:async';
import 'dart:typed_data';
import 'package:P2pChords/networking/nearby/utils.dart';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart'; // Keep for debugPrint
import 'package:nearby_connections/nearby_connections.dart';

// Service
class NearbyService extends CustomeService {
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;

  late Set<String> connectedDeviceIds;
  late Set<String> visibleDevices;
  late Set<String> knownDevices;
  late Reconnection reconnectManager;

  NearbyService._internal();

  final Nearby _nearby = Nearby();

  // Callbacks assigned by ConnectionProvider
  late String userNickName;
  late Function(String) onNotification;
  late Function(String, Payload) onPayloadReceived;

  void _log(String message) {
    debugPrint("NearbyService: $message");
  }

  @override
  void initializeDeviceIds({
    required Set<String> connectedDeviceIds,
    required Set<String> visibleDevices,
    required Set<String> knownDevices,
  }) {
    this.connectedDeviceIds = connectedDeviceIds;
    this.visibleDevices = visibleDevices;
    this.knownDevices = knownDevices;

    // Dont like but okay
    reconnectManager = Reconnection(
      requestConnection: requestConnection,
      connectedDeviceIds: this.connectedDeviceIds,
      knownDevices: this.knownDevices,
    );
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
        // _log("Already advertising. Stopping current advertising session.");
        await stopAdvertising();
      }

      _log("Starting advertising as: $userNickName");
      isAdvertising = true; // Set state before async call

      bool advertisingResult = await _nearby.startAdvertising(
        userNickName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: (id, info) {
          _log("Connection initiated with $id (${info.endpointName})");
          _acceptConnection(id);
        },
        onConnectionResult: (id, status) {
          _log("Connection result for $id: $status");
          if (status == Status.CONNECTED) {
            final added = connectedDeviceIds.add(id);
            knownDevices.add(id);
            if (added) {
              onConnectionStateChanged?.call(); // Notify provider
              onNotification("Verbindung aufgebaut: ${id.substring(0, 4)}");
            }
          } else if (status == Status.REJECTED) {
            onNotification("Verbindung abgelehnt: ${id.substring(0, 4)}");
          } else if (status == Status.ERROR) {
            onNotification("Verbindungsfehler: ${id.substring(0, 4)}");
          }
        },
        onDisconnected: (id) {
          // _log("Disconnected from $id");
          final removed = connectedDeviceIds.remove(id);
          if (removed) {
            onConnectionStateChanged?.call(); // Notify provider
            onNotification("Verbindung getrennt: ${id.substring(0, 4)}");
          }
          // Only attempt reconnection if it was a known device
          if (knownDevices.contains(id)) {
            reconnectManager.startReconnection(id);
          }
        },
      );

      if (!advertisingResult) {
        isAdvertising = false; // Revert state on failure
        onNotification("Fehler beim Starten des Advertisings");
      } else {
        // Optional: Notify success if needed
        // onNotification("Advertising gestartet");
      }

      return advertisingResult;
    } catch (e) {
      isAdvertising = false;
      _log('Error starting advertising: $e'); // Log error for debugging
      onNotification("Fehler beim Starten des Advertisings: $e");
      return false;
    }
  }

  // Start discovery to find other devices
  Future<bool> startDiscovery() async {
    try {
      if (isDiscovering) {
        _log("Already discovering. Stopping current discovery.");
        await stopDiscovery();
      }

      _log("Starting discovery as: $userNickName");
      isDiscovering = true; // Set state before async call

      bool discoveryResult = await _nearby.startDiscovery(
        userNickName,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, serviceId) {
          _log("Found endpoint: $id ($name)");
          final added = visibleDevices.add(id);
          knownDevices.add(id);
          if (added) {
            onConnectionStateChanged?.call();
          }
        },
        onEndpointLost: (id) {
          // _log("Lost endpoint: $id");
          final removed = visibleDevices.remove(id);
          if (removed) {
            onConnectionStateChanged?.call();
          }
        },
      );

      if (!discoveryResult) {
        isDiscovering = false; // Revert state on failure
        onNotification("Fehler beim Starten der Suche");
      } else {
        onNotification("Suche gestartet");
      }

      return discoveryResult;
    } catch (e) {
      isDiscovering = false;
      _log('Error starting discovery: $e');

      onNotification("Fehler beim Starten der Suche: $e");
      return false;
    }
  }

  // Request connection to a discovered endpoint
  Future<bool> requestConnection({required String endpointId}) async {
    try {
      _log("Requesting connection to $endpointId");

      _nearby.requestConnection(
        userNickName,
        endpointId,
        onConnectionInitiated: (id, info) {
          _log(
              "Connection initiated by request with $id (${info.endpointName})");
          _acceptConnection(id);
        },
        onConnectionResult: (id, status) {
          _log("Connection result for request to $id: $status");
          if (status == Status.CONNECTED) {
            final added = connectedDeviceIds.add(id);
            // vielliecht entfernen den add
            knownDevices.add(id);
            if (added) {
              onConnectionStateChanged?.call(); // Notify provider
              onNotification(
                  "Verbindung angefragt & aufgebaut: ${id.substring(0, 4)}");
            }
          } else if (status == Status.REJECTED) {
            onNotification(
                "Verbindungsanfrage abgelehnt: ${id.substring(0, 4)}");
          } else if (status == Status.ERROR) {
            onNotification(
                "Fehler bei Verbindungsanfrage: ${id.substring(0, 4)}");
          }
        },
        onDisconnected: (id) {
          _log("Disconnected from requested connection $id");
          final removed = connectedDeviceIds.remove(id);
          if (removed) {
            onConnectionStateChanged?.call(); // Notify provider
            onNotification(
                "Verbindung getrennt (Anfrage): ${id.substring(0, 4)}");
          }
          // requested connections should trigger auto-reconnect? ka
          if (knownDevices.contains(id)) {
            reconnectManager.startReconnection(id);
          }
        },
      );

      return true; // Indicate the request was sent, not necessarily successful yet
    } catch (e) {
      _log('Error requesting connection: $e'); // Log error for debugging
      onNotification("Fehler bei Verbindungsanfrage: $e");
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
      _log("Error accepting connection: $e");
      onNotification("Fehler beim Akzeptieren der Verbindung: $e");
    });
  }

  // Stop advertising
  Future<bool> stopAdvertising() async {
    try {
      await _nearby.stopAdvertising();
      isAdvertising = false;
      onNotification("Advertising gestoppt");
      return true;
    } catch (e) {
      _log('Error stopping advertising: $e');
      onNotification("Fehler beim Stoppen des Advertisings: $e");
      return false;
    }
  }

  // Stop discovery
  Future<bool> stopDiscovery() async {
    try {
      await _nearby.stopDiscovery();
      isDiscovering = false;
      // Optional: onNotification("Suche gestoppt");
      return true;
    } catch (e) {
      _log('Error stopping discovery: $e');
      onNotification("Fehler beim Stoppen der Suche: $e");
      return false;
    }
  }

  // Disconnect from a specific device
  Future<bool> disconnectFromEndpoint(String endpointId) async {
    try {
      await _nearby.disconnectFromEndpoint(endpointId);
      final removed = connectedDeviceIds.remove(endpointId);
      knownDevices.remove(
          endpointId); // Remove from known devices to prevent reconnection
      if (removed) {
        onConnectionStateChanged?.call(); // Notify provider
        onNotification(
            "Verbindung manuell getrennt: ${endpointId.substring(0, 4)}");
      }
      return true;
    } catch (e) {
      _log('Error disconnecting from endpoint: $e');
      onNotification("Fehler beim Trennen der Verbindung: $e");
      return false;
    }
  }

  // Disconnect from all connected devices
  Future<void> disconnectFromAllEndpoints() async {
    try {
      if (connectedDeviceIds.isNotEmpty) {
        // Only notify if there were connections
        await _nearby.stopAllEndpoints();
        final hadConnections = connectedDeviceIds.isNotEmpty;
        connectedDeviceIds.clear();
        knownDevices.clear(); // Clear known devices to prevent reconnection
        if (hadConnections) {
          onConnectionStateChanged?.call(); // Notify change
          onNotification("Alle Verbindungen getrennt");
        }
      } else {
        await _nearby
            .stopAllEndpoints(); // Still stop endpoints even if set was empty
        knownDevices.clear();
      }
    } catch (e) {
      _log('Error disconnecting from all endpoints: $e');
      onNotification("Fehler beim Trennen aller Verbindungen: $e");
    }
  }

  Future<bool> sendBytesPayload(String endpointId, Uint8List bytes) async {
    try {
      await _nearby.sendBytesPayload(endpointId, bytes);
      return true;
    } catch (e) {
      _log('Error sending bytes payload: $e');
      // Maybe notify user? Depends on context.
      onNotification("Fehler beim Senden von Daten: $e");
      return false;
    }
  }

  // Clean up resources
  @override
  Future<void> dispose() async {
    await reconnectManager.dispose();
    await disconnectFromAllEndpoints();
    await stopAdvertising();
    await stopDiscovery();
  }
}
