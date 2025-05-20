import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:bonsoir/bonsoir.dart';
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

  // Bonsoir variables
  BonsoirBroadcast? _bonsoirBroadcast;
  BonsoirDiscovery? _bonsoirDiscovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySubscription;
  static const String _serviceType = '_p2pchords._tcp'; // Bonsoir service type

  // Notification callback for important events
  late String userNickName;
  late Function(String) onNotification;
  late Function(String) onMessageReceived;
  late Function(String) addConnectedDevice;

  late Set<String> connectedDeviceIds;
  late Set<String> visibleDevices; // Stores "ip:port" of discovered services
  late Set<String> knownDevices;

  WebSocket? _clientToServerSocket;

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
    _notify("Starting client and Bonsoir discovery...");
    await startBonsoirDiscovery();
    onConnectionStateChanged?.call();
    return isDiscovering;
  }

  @override
  Future<bool> stopClient() async {
    _notify("Stopping client operations and Bonsoir discovery...");
    await stopBonsoirDiscovery();

    if (_clientToServerSocket != null) {
      try {
        await _clientToServerSocket!.close();
        _notify("Closed client connection to server.");
      } catch (e) {
        _notify("Error closing client connection to server: $e");
      }
      _clientToServerSocket = null;
    }
    onConnectionStateChanged?.call();
    return !isDiscovering; // Return true if discovery stopped successfully
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
        _notify('Invalid server address format. Use IP:PORT. Got: $serverId');
        return false;
      }

      final ip = parts[0];
      final port = int.tryParse(parts[1]);

      if (port == null) {
        _notify('Invalid port in server address: $serverId');
        return false;
      }

      final wsUrl = 'ws://$ip:$port';
      _notify('Attempting to connect to $wsUrl');

      _clientToServerSocket = await WebSocket.connect(wsUrl)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        _clientToServerSocket = null;
        throw TimeoutException('Connection timed out');
      });

      final initialMessage = {
        'type': 'listening',
        'content': {
          'name': userNickName,
          'id': _uuid.v4(),
        },
      };

      _clientToServerSocket!.add(jsonEncode(initialMessage));

      connectedDeviceIds.add(serverId);
      knownDevices.add(serverId);
      if (visibleDevices.contains(serverId)) {
        visibleDevices.remove(serverId);
      }
      onConnectionStateChanged?.call();

      _clientToServerSocket!.listen(
        (dynamic data) {
          try {
            String jsonString;
            if (data is String) {
              String cleanData = data;
              if (cleanData.startsWith('"') && cleanData.endsWith('"')) {
                cleanData = cleanData.substring(1, cleanData.length - 1);
              }
              jsonString = utf8.decode(base64.decode(cleanData));
            } else {
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
          _clientToServerSocket = null;
        },
        onError: (error) {
          _notify('WebSocket error with server $serverId: $error');
          connectedDeviceIds.remove(serverId);
          onConnectionStateChanged?.call();
          _clientToServerSocket = null;
        },
        cancelOnError: true,
      );
      onConnectionStateChanged?.call();
      _notify('Successfully connected to server at $wsUrl');
      return true;
    } catch (e) {
      _notify('Error connecting to server $serverId: $e');
      if (_clientToServerSocket != null &&
          _clientToServerSocket?.closeCode == null) {
        _clientToServerSocket = null;
      }
      if (connectedDeviceIds.contains(serverId)) {
        connectedDeviceIds.remove(serverId);
        onConnectionStateChanged?.call();
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
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return "${addr.address}:$port";
          }
        }
      }
      return "${InternetAddress.loopbackIPv4.address}:$port";
    } catch (e) {
      debugPrint('Error getting server address: $e');
      return "${InternetAddress.loopbackIPv4.address}:$port";
    }
  }

  Future<void> startBonsoirDiscovery() async {
    // Corrected: Rely on isDiscovering flag and null check for _bonsoirDiscovery
    if (isDiscovering && _bonsoirDiscovery != null) {
      _notify("Bonsoir discovery already active.");
      return;
    }
    try {
      _bonsoirDiscovery = BonsoirDiscovery(type: _serviceType);
      await _bonsoirDiscovery!.ready;

      visibleDevices
          .clear(); // Clear previous visible devices before starting new discovery
      onConnectionStateChanged?.call();

      _discoverySubscription = _bonsoirDiscovery!.eventStream!.listen(
        (event) {
          if (event.service == null) return;

          if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
            print('FOUND');
            _notify('Bonsoir: Service found: ${event.service!.name}');
            // Request resolution
            event.service!.resolve(_bonsoirDiscovery!.serviceResolver);
          } else if (event.type ==
              BonsoirDiscoveryEventType.discoveryServiceResolved) {
            final resolvedService = event.service as ResolvedBonsoirService;
            final serverAddress =
                "${resolvedService.host}:${resolvedService.port}";
            _notify(
                'Bonsoir: Service resolved: ${resolvedService.name} at $serverAddress');
            if (!visibleDevices.contains(serverAddress) &&
                !connectedDeviceIds.contains(serverAddress)) {
              visibleDevices.add(serverAddress);
              onConnectionStateChanged?.call();
              _notify("Bonsoir: Added $serverAddress to visible devices.");
            }
          } else if (event.type ==
              BonsoirDiscoveryEventType.discoveryServiceLost) {
            _notify('Bonsoir: Service lost: ${event.service!.name}');
            if (event.service is ResolvedBonsoirService) {
              final lostService = event.service as ResolvedBonsoirService;
              final serverAddress = "${lostService.host}:${lostService.port}";
              if (visibleDevices.remove(serverAddress)) {
                onConnectionStateChanged?.call();
                _notify(
                    "Bonsoir: Removed $serverAddress from visible devices.");
              }
            } else {
              _notify(
                  "Bonsoir: Lost service ${event.service!.name} was not resolved, cannot remove by IP:Port directly.");
            }
          }
        },
        onError: (dynamic error) {
          String errorMessage = 'Bonsoir discovery error: $error';
          if (error is Error) {
            errorMessage += '\nStack trace: ${error.stackTrace}';
          }
          _notify(errorMessage);
          isDiscovering = false; // Ensure flag is reset on error
          onConnectionStateChanged?.call();
        },
        onDone: () {
          _notify('Bonsoir discovery stream closed.');
          isDiscovering = false; // Ensure flag is reset when stream is done
          onConnectionStateChanged?.call();
        },
      );
      await _bonsoirDiscovery!.start();
      isDiscovering = true; // Set after successful start
      _notify("Bonsoir discovery started for type '$_serviceType'.");
      onConnectionStateChanged?.call();
    } catch (e) {
      _notify("Error starting Bonsoir discovery: $e");
      isDiscovering = false; // Ensure flag is reset on error
      if (_bonsoirDiscovery != null) {
        try {
          // Corrected: No need to check _bonsoirDiscovery.isSearching, just stop if it was initialized
          await _bonsoirDiscovery!.stop();
        } catch (stopError) {
          _notify(
              "Error trying to stop Bonsoir discovery during error handling: $stopError");
        }
      }
      _bonsoirDiscovery = null; // Nullify on error
      await _discoverySubscription?.cancel(); // Cancel if subscription was made
      _discoverySubscription = null;
      onConnectionStateChanged?.call(); // Reflect state change
    }
  }

  Future<void> stopBonsoirDiscovery() async {
    if (_bonsoirDiscovery != null) {
      _notify("Stopping Bonsoir discovery.");
      try {
        await _bonsoirDiscovery!.stop();
      } catch (e) {
        _notify("Error during Bonsoir discovery stop: $e");
      }
      await _discoverySubscription?.cancel();
      _discoverySubscription = null;
      _bonsoirDiscovery = null; // Dispose of the object

      if (isDiscovering) {
        isDiscovering = false;
        onConnectionStateChanged?.call();
        _notify("Bonsoir discovery stopped.");
      }
    } else {
      if (isDiscovering) {
        isDiscovering = false;
        onConnectionStateChanged?.call();
        _notify(
            "Bonsoir discovery was marked active but object was null. State corrected.");
      }
    }
  }

  Future<List<String>> startDiscovery() async {
    _notify(
        "Bonsoir discovery initiated via startClient(). Check visibleDevices.");
    if (!isDiscovering) {
      await startClient(); // This will call _startBonsoirDiscovery
    }
    return visibleDevices.toList(); // Returns a snapshot
  }

  Future<bool> startAdvertising() async {
    // Corrected: Rely on isAdvertising flag and null check for _bonsoirBroadcast
    if (isAdvertising && _bonsoirBroadcast != null) {
      _notify('Server is already advertising (Bonsoir)');
      return true;
    }
    if (isServerRunning && _httpServer == null) {
      _notify(
          "Server was marked as running but HTTP server is null. Attempting to stop and restart.");
      await stopAdvertising(); // Try to clean up inconsistent state
    }

    try {
      if (_httpServer == null) {
        const port = 0;
        try {
          _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
          _notify('WebSocket server started on port ${_httpServer!.port}');
        } catch (e) {
          _notify('Failed to start WebSocket server: $e');
          isServerRunning = false;
          isAdvertising = false;
          return false;
        }
      }
      isServerRunning = true;

      final serviceName =
          'P2PChords-${userNickName.replaceAll(' ', '_')}-${_uuid.v4().substring(0, 4)}';
      final service = BonsoirService(
        name: serviceName,
        type: _serviceType,
        port: _httpServer!.port,
      );

      _bonsoirBroadcast = BonsoirBroadcast(service: service);
      await _bonsoirBroadcast!.ready;
      await _bonsoirBroadcast!.start();

      isAdvertising = true; // Set after successful start
      _notify(
          "Bonsoir: Service '$serviceName' advertised on port ${_httpServer!.port}.");
      onConnectionStateChanged?.call();

      _httpServer!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          try {
            final socket = await WebSocketTransformer.upgrade(request);
            socket.listen(
              (dynamic data) {
                try {
                  final message = jsonDecode(data);
                  String? clientIdFromMessage;
                  String? clientNameFromMessage;

                  if (message.containsKey('type') &&
                      message['type'] == 'listening' &&
                      message.containsKey('content')) {
                    clientIdFromMessage = message['content']['id'] as String?;
                    clientNameFromMessage =
                        message['content']['name'] as String?;
                  }

                  if (clientIdFromMessage != null &&
                      clientNameFromMessage != null &&
                      !_clients
                          .any((client) => client.id == clientIdFromMessage)) {
                    final client = WebSocketClient(
                        clientIdFromMessage, clientNameFromMessage, socket);
                    _clients.add(client);

                    connectedDeviceIds.add(clientIdFromMessage);
                    knownDevices.add(clientIdFromMessage);
                    onConnectionStateChanged?.call();
                    SnackService().showInfo(
                        'Client connected: $clientNameFromMessage ($clientIdFromMessage)');
                    _notify(
                        "Client connected: $clientNameFromMessage ($clientIdFromMessage)");
                  } else if (_clients.any((c) => c.socket == socket)) {
                    String jsonString;
                    if (data is String) {
                      String cleanData = data;
                      if (cleanData.startsWith('"') &&
                          cleanData.endsWith('"')) {
                        cleanData =
                            cleanData.substring(1, cleanData.length - 1);
                      }
                      jsonString = utf8.decode(base64.decode(cleanData));
                    } else {
                      jsonString = utf8.decode(base64.decode(data));
                    }
                    onMessageReceived(jsonString);
                  } else {
                    _notify(
                        "Received message from unknown or unassociated socket, or malformed initial message.");
                  }
                } catch (e) {
                  _notify('Error processing message: $e. Data: $data');
                }
              },
              onDone: () {
                final client = _clients.firstWhere((c) => c.socket == socket,
                    orElse: () => WebSocketClient("", "", socket));
                if (client.id.isNotEmpty) {
                  disconnectFromEndpoint(client.id);
                } else {
                  _notify(
                      "Socket closed for a client not fully registered or already removed.");
                }
              },
              onError: (error) {
                final client = _clients.firstWhere((c) => c.socket == socket,
                    orElse: () => WebSocketClient("", "", socket));
                if (client.id.isNotEmpty) {
                  SnackService()
                      .showError('WebSocket error for ${client.name}: $error');
                  disconnectFromEndpoint(client.id);
                } else {
                  _notify(
                      "WebSocket error for a client not fully registered or already removed: $error");
                }
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
      SnackService().showError(
          'Failed to start WebSocket server or Bonsoir advertising: $e');
      _notify('Failed to start WebSocket server or Bonsoir advertising: $e');
      isServerRunning = false; // Ensure flags are reset
      isAdvertising = false;

      if (_bonsoirBroadcast != null) {
        // Check if broadcast object exists
        try {
          // Corrected: No need to check _bonsoirBroadcast.isBroadcasting
          await _bonsoirBroadcast!.stop();
        } catch (stopError) {
          _notify(
              "Error stopping Bonsoir broadcast during error handling: $stopError");
        }
      }
      _bonsoirBroadcast = null; // Nullify on error

      await _httpServer?.close(force: true);
      _httpServer = null;
      onConnectionStateChanged?.call(); // Reflect state change
      return false;
    }
  }

  Future<bool> stopAdvertising() async {
    bool wasAdvertising = isAdvertising; // Capture original state

    try {
      // Corrected: Rely on isAdvertising flag and null check
      if (_bonsoirBroadcast != null && isAdvertising) {
        _notify(
            "Bonsoir: Unadvertising service '${_bonsoirBroadcast!.service.name}'.");
        try {
          // Corrected: Removed _bonsoirBroadcast.isBroadcasting check
          await _bonsoirBroadcast!.stop();
          _notify("Bonsoir: Service unadvertised.");
        } catch (e) {
          _notify("Error stopping Bonsoir broadcast: $e");
          // Still proceed with cleanup
        }
      }
      _bonsoirBroadcast = null; // Always nullify
      isAdvertising = false; // Set after attempting to stop

      for (final client in _clients.toList()) {
        await client.disconnect(userNickName, _uuid.v4());
      }
      _clients.clear();

      await _httpServer?.close(force: true);
      _httpServer = null;
      isServerRunning = false;
      _notify('WebSocket server stopped');

      if (wasAdvertising || isServerRunning) {
        // If advertising state or server state changed
        onConnectionStateChanged?.call();
      }

      return true;
    } catch (e) {
      _notify('Error stopping WebSocket server or Bonsoir advertising: $e');
      isAdvertising = false; // Ensure flags are reset on error
      isServerRunning = false;
      _bonsoirBroadcast = null; // Ensure cleanup
      _httpServer = null;
      onConnectionStateChanged?.call(); // Reflect state change
      return false;
    }
  }

  Future<bool> disconnectFromEndpoint(String clientId) async {
    try {
      WebSocketClient? clientToRemove;
      try {
        clientToRemove = _clients.firstWhere((client) => client.id == clientId);
      } catch (e) {
        _notify(
            'Client $clientId not found for disconnection. Already removed or invalid ID.');
        if (connectedDeviceIds.contains(clientId)) {
          connectedDeviceIds.remove(clientId);
          onConnectionStateChanged?.call();
        }
        return false;
      }

      await clientToRemove.socket.close();
      _clients.remove(clientToRemove);
      connectedDeviceIds.remove(clientId);
      onConnectionStateChanged?.call();
      _notify('Client ${clientToRemove.name} ($clientId) disconnected.');
      return true;
    } catch (e) {
      _notify('Error handling client disconnect for $clientId: $e');
      if (connectedDeviceIds.contains(clientId)) {
        connectedDeviceIds.remove(clientId);
        onConnectionStateChanged?.call();
      }
      _clients.removeWhere((c) => c.id == clientId);
      return false;
    }
  }

  Future<bool> sendBytesPayload(String clientId, Uint8List bytes) async {
    try {
      final client = _clients.firstWhere(
        (client) => client.id == clientId,
      );
      client.send(base64Encode(bytes));
      return true;
    } catch (e) {
      _notify(
          'Error sending bytes payload to $clientId: $e. Client may not be connected.');
      return false;
    }
  }

  void _notify(String message) {
    debugPrint("WebSocketService: $message");
    onNotification.call(message);
  }

  @override
  Future<void> dispose() async {
    _notify("Disposing WebSocketService...");
    await stopClient();
    await stopServer();
    // Bonsoir objects should be nullified by stopClient/stopServer
    _notify("WebSocketService disposed.");
  }
}
