import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';

/// Client connection to WebSocket server
class WebSocketClient {
  final String id;
  final String name;
  final WebSocket socket;

  WebSocketClient(this.id, this.name, this.socket);

  Future<void> disconnect(name, id) async {
    send({
      'type': 'disconnect',
      'content': {
        'name': name,
        'id': id,
      }
    });
    await socket.close();
  }

  void send(dynamic data) {
    if (socket.readyState == WebSocket.open) {
      //socket.add(jsonEncode(data));
      socket.add(data);
    }
  }
}

/// WebSocket service handling server-side WebSocket connections
class WebSocketService extends CustomeService {
  // Singleton pattern to match NearbyService
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal();
  // Server variables
  HttpServer? _httpServer;
  final Set<WebSocketClient> _clients = {};
  final _uuid = const Uuid();

  // Notification callback for important events
  late String userNickName;
  late Function(String) onNotification;
  late Function(String) onMessageReceived;
  late Function(String) addConnectedDevice;

  late Set<String> connectedDeviceIds;
  late Set<String> visibleDevices;
  late Set<String> knownDevices;

  RawDatagramSocket? _discoveryListenerSocket;
  String? _listeningForClientId;
  WebSocket? _clientToServerSocket;
  static const int QR_DISCOVERY_PORT = 45679;

  // Getters
  List<WebSocketClient> get clients => _clients.toList();

  @override
  void initializeDeviceIds({
    required Set<String> connectedDeviceIds,
    required Set<String> visibleDevices,
    required Set<String> knownDevices,
  }) {
    this.connectedDeviceIds = connectedDeviceIds;
    this.visibleDevices = visibleDevices;
    this.knownDevices = knownDevices;
  }

  // Override base class methods to match NearbyService
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
    return true;
  }

  @override
  Future<bool> stopClient() async {
    _notify("Stopping client operations...");
    await stopListeningForServerAnnouncement(); // Stop UDP listener

    if (_clientToServerSocket != null) {
      try {
        // The onDone/onError handlers in listenOnServer should remove from connectedDeviceIds
        await _clientToServerSocket!.close();
        _notify("Closed client connection to server.");
      } catch (e) {
        _notify("Error closing client connection to server: $e");
      }
      _clientToServerSocket = null;
    }
    // Consider if connectedDeviceIds related to this client's connection should be cleared here
    // or rely on onDone/onError in listenOnServer.
    return true;
  }

  @override
  Future<bool> connectToServer(String serverId) => listenOnServer(serverId);

  Future<bool> listenOnServer(String serverId) async {
    if (_clientToServerSocket != null &&
        _clientToServerSocket!.readyState == WebSocket.open) {
      _notify(
          "Already connected to a server. Please disconnect first or implement multi-server support.");
      return false;
    }

    final ownAddress = await getServerAddress();
    if (ownAddress != null && serverId == ownAddress) {
      _notify("Cannot connect to self.");
      return false;
    }

    try {
      final parts = serverId.split(':');
      if (parts.length != 2) {
        _notify('Invalid server address format. Use IP:PORT');
        return false;
      }

      final ip = parts[0];
      final port = int.parse(parts[1]);

      final wsUrl = 'ws://$ip:$port';
      _notify('Attempting to connect to $wsUrl');

      _clientToServerSocket = await WebSocket.connect(wsUrl)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        _clientToServerSocket = null; // Ensure socket is nulled on timeout
        throw TimeoutException('Connection timed out');
      });

      final initialMessage = {
        'type':
            'listening', // Or a more client-specific type like 'client_hello'
        'content': {
          'name': userNickName,
          'id': _uuid.v4(), // Unique ID for this connection instance
        },
      };

      _clientToServerSocket!.add(jsonEncode(initialMessage));

      // Add to connected devices
      connectedDeviceIds
          .add(serverId); // serverId here is the address of the server
      knownDevices.add(serverId);

      onConnectionStateChanged?.call();

      // Set up listener for incoming messages
      _clientToServerSocket!.listen(
        (dynamic data) {
          //print('Received data: $data');
          try {
            // A bit wanky, but it dont know how to decode the data otherwise
            String jsonString;
            if (data is String) {
              // Remove quotes if present at beginning and end
              String cleanData = data;
              if (cleanData.startsWith('"') && cleanData.endsWith('"')) {
                cleanData = cleanData.substring(1, cleanData.length - 1);
              }
              jsonString = utf8.decode(base64.decode(cleanData));
            } else {
              // Now really decode the data
              jsonString = utf8.decode(base64.decode(data));
            }

            onMessageReceived(jsonString);
          } catch (e) {
            _notify('Error processing message: $e');
          }
        },
        onDone: () {
          _notify('Connection to server $serverId closed');
          connectedDeviceIds.remove(serverId);
          onConnectionStateChanged?.call();
          _clientToServerSocket = null; // Clear the socket reference
        },
        onError: (error) {
          _notify('WebSocket error with server $serverId: $error');
          connectedDeviceIds.remove(serverId);
          onConnectionStateChanged?.call();
          _clientToServerSocket = null; // Clear the socket reference
        },
        cancelOnError: true,
      );

      _notify('Successfully connected to server at $wsUrl');
      return true;
    } catch (e) {
      _notify('Error connecting to server $serverId: $e');
      if (_clientToServerSocket != null &&
          _clientToServerSocket?.closeCode == null) {
        // If connect threw after socket was assigned but before fully established or if timeout didn't null it
        _clientToServerSocket = null;
      }
      return false;
    }
  }

  Future<String?> getServerAddress() async {
    if (_httpServer == null || !isServerRunning) {
      return null;
    }

    final port = _httpServer!.port;

    try {
      // Get all network interfaces
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Find a suitable network address (not loopback)
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return "${addr.address}:$port";
          }
        }
      }

      // Fallback if no suitable interface found
      return "127.0.0.1:$port"; // maybe make null
    } catch (e) {
      debugPrint('Error getting server address: $e');
      return "127.0.0.1:$port"; //also this
    }
  }

  Future<void> announceServerToClient(String clientQRCodeId) async {
    final serverAddress = await getServerAddress();
    if (serverAddress == null) {
      _notify("Server address not available. Cannot announce.");
      return;
    }

    try {
      // Use a temporary socket for sending the broadcast
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final messagePayload = jsonEncode({
        'type': 'SERVER_ANNOUNCEMENT_FOR_CLIENT',
        'serverAddress': serverAddress,
        'targetClientId': clientQRCodeId,
      });

      final data = utf8.encode(messagePayload);
      // Sends to the broadcast address on the dedicated QR discovery port
      socket.send(data, InternetAddress('255.255.255.255'), QR_DISCOVERY_PORT);
      _notify(
          'Announced server $serverAddress for client ID $clientQRCodeId via broadcast on port $QR_DISCOVERY_PORT.');
      socket.close(); // Close the socket after sending
    } catch (e) {
      _notify('Error announcing server to client: $e');
    }
  }

  Future<bool> listenForServerAnnouncement(String clientQRCodeId) async {
    if (_discoveryListenerSocket != null) {
      // If already listening, decide on behavior (e.g., stop old, start new)
      if (_listeningForClientId == clientQRCodeId) {
        _notify(
            "Already listening for server announcement for this ID: $clientQRCodeId.");
        return true; // Already correctly listening
      }
      // Stop previous listener if it was for a different ID or to refresh
      await stopListeningForServerAnnouncement();
    }

    _listeningForClientId = clientQRCodeId;
    _notify(
        "Client listening for server announcement for ID: $_listeningForClientId on port $QR_DISCOVERY_PORT");

    try {
      _discoveryListenerSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4, QR_DISCOVERY_PORT);
      _discoveryListenerSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _discoveryListenerSocket!.receive();
          if (datagram == null) return;

          try {
            final messageString = String.fromCharCodes(datagram.data);
            final messageJson = jsonDecode(messageString);

            print(
                'Received UDP data from ${datagram.address}:${datagram.port}: "$messageString"');

            if (messageJson['type'] == 'SERVER_ANNOUNCEMENT_FOR_CLIENT' &&
                messageJson['targetClientId'] == _listeningForClientId) {
              final serverAddress = messageJson['serverAddress'] as String;
              print('JOE: $serverAddress');
              _notify(
                  'Received server announcement: $serverAddress for my ID $_listeningForClientId. Attempting to connect...');

              // Stop listening once the target message is received and processed.
              // Do this before attempting to connect to avoid race conditions or further processing.
              stopListeningForServerAnnouncement();

              connectToServer(serverAddress).then((success) {
                if (success) {
                  _notify(
                      "Successfully connected to server $serverAddress via QR code announcement.");
                } else {
                  _notify(
                      "Failed to connect to server $serverAddress after QR code announcement.");
                  // UI should handle this, possibly allowing user to retry listening.
                }
              });
            }
          } catch (e) {
            // Silently ignore packets that are not in the expected JSON format or not for us
            // debugPrint('UDP: Error processing packet or not our message: $e');
          }
        }
      }, onError: (error) {
        _notify('UDP listener error for ID $_listeningForClientId: $error');
        stopListeningForServerAnnouncement(); // Clean up on error
      }, onDone: () {
        // This is called when the socket is closed.
        // _notify('UDP listener stopped for ID: $_listeningForClientId.');
        // _listeningForClientId and _discoveryListenerSocket are nulled by stopListeningForServerAnnouncement
      });
      return true;
    } catch (e) {
      _notify(
          'Error setting up UDP listener for server announcement (ID $clientQRCodeId): $e');
      _listeningForClientId = null; // Clear ID if setup failed
      if (_discoveryListenerSocket != null) {
        _discoveryListenerSocket!.close();
        _discoveryListenerSocket = null;
      }
      return false;
    }
  }

  /// Stops the UDP listener for server announcements.
  Future<void> stopListeningForServerAnnouncement() async {
    if (_discoveryListenerSocket != null) {
      _notify(
          "Stopping UDP listener for server announcements (ID: $_listeningForClientId).");
      _discoveryListenerSocket!.close();
      _discoveryListenerSocket = null;
      _listeningForClientId = null;
    }
  }

  Future<List<String>> startDiscovery() async {
    //  final discoveredServers = <String>[];
    //  final completer = Completer<List<String>>();
//
    //  try {
    //    // Bind to any available port for sending/receiving discovery
    //    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//
    //    socket.broadcastEnabled = true; // Enable broadcast
    //    // Set up listener for responses
    //    socket.listen((event) {
    //      if (event == RawSocketEvent.read) {
    //        final datagram = socket.receive();
    //        if (datagram == null) return;
//
    //        final message = String.fromCharCodes(datagram.data);
    //        if (message.startsWith('P2P_CHORDS_SERVER:')) {
    //          final serverInfo = message.split(':');
    //          if (serverInfo.length == 3) {
    //            final ip = serverInfo[1];
    //            final port = serverInfo[2];
    //            final serverAddress = '$ip:$port';
//
    //            if (!discoveredServers.contains(serverAddress)) {
    //              discoveredServers.add(serverAddress);
    //              print('Found server via UDP broadcast: $serverAddress');
    //            }
    //          }
    //        }
    //      }
    //    });
//
    //    // Broadcast discovery message
    //    _notify('Broadcasting discovery message...');
    //    final broadcastAddress = InternetAddress('255.255.255.255');
    //    socket.send(
    //        'P2P_CHORDS_DISCOVERY'.codeUnits, broadcastAddress, DISCOVERY_PORT);
//
    //    // Wait for responses (2 seconds)
    //    await Future.delayed(const Duration(seconds: 2));
//
    //    // Clean up
    //    socket.close();
    //    completer.complete(discoveredServers);
    //  } catch (e) {
    //    _notify('Discovery failed: $e');
    //    completer.complete([]);
    //  }
//
    //  return completer.future;
    return [];
  }

  // WebSocket-specific methods with similar patterns to NearbyService
  Future<bool> startAdvertising() async {
    try {
      if (isServerRunning) {
        _notify('Server is already running');
        return true;
      }
      if (isAdvertising) {
        _notify('Server is already advertising');
        return true;
      }

      const port =
          0; // Dynamic port assignment, OS will choose an available one

      try {
        _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
        final assignedPort = _httpServer!.port;
        print(_httpServer);

        _notify('WebSocket server started on port $assignedPort');
      } catch (e) {
        print('DETAILED ERROR: Failed to start WebSocket server: $e');
        _notify('Failed to start WebSocket server: $e');
        return false;
      }
      isServerRunning = true;
      isAdvertising = true;

      _httpServer!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          try {
            final socket = await WebSocketTransformer.upgrade(request);
            final clientId = _uuid.v4();

            // Wait for initial message with client name
            socket.listen(
              (dynamic data) {
                try {
                  final message = jsonDecode(data);

                  // Handle initial connection
                  if (!_clients.any((client) => client.id == clientId)) {
                    if (message.containsKey('type')) {
                      if (message['type'] == 'listening') {
                        // Handle connection established message
                        final clientName = message['content']['name'] as String;
                        final clientId = message['content']['id'] as String;
                        final client =
                            WebSocketClient(clientId, clientName, socket);
                        _clients.add(client);

                        // Add to connected devices
                        connectedDeviceIds.add(clientId);
                        knownDevices.add(clientId);
                        onConnectionStateChanged?.call();

                        SnackService()
                            .showInfo('Client connected: $clientName');
                      }
                    }
                  }
                  // Handle messages from connected clients
                  else {
                    onMessageReceived(message);
                  }
                } catch (e) {
                  _notify('Error processing message: $e');
                }
              },
              onDone: () => disconnectFromEndpoint(clientId),
              onError: (error) {
                SnackService().showError('WebSocket error: $error');
                disconnectFromEndpoint(clientId);
              },
              cancelOnError: true,
            );
          } catch (e) {
            _notify('Error during WebSocket upgrade: $e');
          }
        }
      });

      return true;
    } catch (e) {
      SnackService().showError('Failed to start WebSocket server: $e');
      isServerRunning = false;
      isAdvertising = false;
      return false;
    }
  }

  Future<bool> stopAdvertising() async {
    try {
      // Disconnect all clients
      for (final client in _clients.toList()) {
        await client.disconnect(userNickName, _uuid.v4());
      }

      _clients.clear();
      connectedDeviceIds.clear();

      // Close server
      await _httpServer?.close();
      _httpServer = null;
      isServerRunning = false;
      isAdvertising = false;
      _notify('WebSocket server stopped');
      onConnectionStateChanged?.call();

      return true;
    } catch (e) {
      _notify('Error stopping WebSocket server: $e');
      onConnectionStateChanged?.call();

      return false;
    }
  }

  /// Handle client disconnection
  Future<bool> disconnectFromEndpoint(String clientId) async {
    try {
      final client = _clients.firstWhere(
        (client) => client.id == clientId,
        orElse: () => throw Exception('Client not found'),
      );

      final disconnectMessage = {
        'type': 'disconnect',
        'content': {
          'name': userNickName,
          'id': clientId,
        },
      };

      client.send(jsonEncode(disconnectMessage));

      _clients.remove(client);
      connectedDeviceIds.remove(clientId);
      onConnectionStateChanged?.call();
      _notify('Client ${client.name} disconnected');
      return true;
    } catch (e) {
      _notify('Error handling client disconnect: $e');
      return false;
    }
  }

  Future<bool> sendBytesPayload(String clientId, Uint8List bytes) async {
    try {
      final client = _clients.firstWhere(
        (client) => client.id == clientId,
        orElse: () => throw Exception('Client not found'),
      );

      client.send(
        base64Encode(bytes),
      );
      return true;
    } catch (e) {
      _notify('Error sending bytes payload: $e');
      return false;
    }
  }

  /// Display notification - matching NearbyService pattern
  void _notify(String message) {
    debugPrint(message);
    onNotification.call(message);
  }

  @override
  Future<void> dispose() async {
    await stopClient(); // Ensure client resources are freed
    await stopServer(); // Ensure server resources are freed (stopAdvertising handles this)
    // Original dispose only called stopAdvertising. Adding stopClient for completeness.
  }
}
