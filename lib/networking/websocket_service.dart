import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:P2pChords/state.dart';
import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';

/// Client connection to WebSocket server
class WebSocketClient {
  final String id;
  final String name;
  final WebSocket socket;

  WebSocketClient(this.id, this.name, this.socket);

  Future<void> disconnect() async {
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

  WebSocketService._internal() {
    // Initialize empty sets to match NearbyService
    connectedDeviceIds = {};
    visibleDevices = {};
    knownDevices = {};
  }

  // Server variables
  HttpServer? _httpServer;
  final Set<WebSocketClient> _clients = {};
  final _uuid = const Uuid();

  // Notification callback for important events
  late String userNickName;
  late Function(String) onNotification;
  late Function(String) onPayloadReceived;
  late Function(String) addConnectedDevice;

  // Getters
  List<WebSocketClient> get clients => _clients.toList();

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
    print("NOT IMPLEMENTED: stopClient");
    return true;
  }

  @override
  Future<bool> connectToServer(String serverId) async {
    if (serverId == await getServerAddress()) {
      _notify('Cannot connect to self');
      return false;
    }
    // Parse address into IP and port
    try {
      final parts = serverId.split(':');
      if (parts.length != 2) {
        _notify('Invalid server address format. Use IP:PORT');
        return false;
      }

      final ip = parts[0];
      final port = int.parse(parts[1]);

      // Create WebSocket URL
      final wsUrl = 'ws://$ip:$port';
      _notify('Attempting to connect to $wsUrl');

      // Connect to the WebSocket server
      final socket = await WebSocket.connect(wsUrl).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );
      final clientId = _uuid.v4();

      final initialMessage = {
        'type': 'connection_established',
        'content': {
          'name': userNickName,
          'id': clientId,
        },
      };

      socket.add(jsonEncode(initialMessage));

      // Add to connected devices
      connectedDeviceIds.add(serverId);
      knownDevices.add(serverId);

      // Set up listener for incoming messages
      socket.listen(
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

            onPayloadReceived(jsonString);
          } catch (e) {
            _notify('Error processing message: $e');
          }
        },
        onDone: () {
          _notify('Connection to server closed');
          connectedDeviceIds.remove(serverId);
          //_isReconnecting = false;
        },
        onError: (error) {
          _notify('WebSocket error: $error');
          connectedDeviceIds.remove(serverId);
          //_isReconnecting = false;
        },
        cancelOnError: true,
      );
      // Store the connection for future use? Maybe good idea
      //_serverConnection = WebSocketClient(serverAddress, 'Server', socket);

      _notify('Successfully connected to server at $wsUrl');
      return true;
    } catch (e) {
      _notify('Error connecting to server: $e');
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
                      if (message['type'] == 'connection_established') {
                        // Handle connection established message
                        final clientName = message['content']['name'] as String;
                        final clientId = message['content']['id'] as String;
                        final client =
                            WebSocketClient(clientId, clientName, socket);
                        _clients.add(client);

                        // Add to connected devices
                        connectedDeviceIds.add(clientId);
                        knownDevices.add(clientId);

                        // Notify about new connection
                        _notify('Client connected: $clientName');
                      }
                    }
                  }
                  // Handle messages from connected clients
                  else {
                    onPayloadReceived(message);
                  }
                } catch (e) {
                  _notify('Error processing message: $e');
                }
              },
              onDone: () => disconnectFromEndpoint(clientId),
              onError: (error) {
                _notify('WebSocket error: $error');
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
      _notify('Failed to start WebSocket server: $e');
      isServerRunning = false;
      isAdvertising = false;
      return false;
    }
  }

  Future<bool> stopAdvertising() async {
    try {
      // Disconnect all clients
      for (final client in _clients.toList()) {
        await client.disconnect();
      }
      _clients.clear();
      connectedDeviceIds.clear();

      // Close server
      await _httpServer?.close();
      _httpServer = null;
      isServerRunning = false;
      isAdvertising = false;
      _notify('WebSocket server stopped');
      return true;
    } catch (e) {
      _notify('Error stopping WebSocket server: $e');
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

  /// Clean up resources
  Future<void> dispose() async {
    await stopAdvertising();
  }
}
