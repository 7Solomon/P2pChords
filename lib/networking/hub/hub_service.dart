import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart'; // ADD THIS for IOWebSocketChannel
import '../models/connection_models.dart';

class HubService {
  static final HubService _instance = HubService._internal();
  factory HubService() => _instance;
  HubService._internal();

  // Configuration
  static const String serviceType = '_p2pchords._tcp';
  static const Duration healthCheckInterval = Duration(seconds: 10);
  static const Duration clientTimeout = Duration(seconds: 30);

  // State
  HttpServer? _httpServer;
  BonsoirBroadcast? _broadcast;
  final Map<String, SpokeConnection> _spokes = {};
  final _uuid = const Uuid();
  
  String? _hubId;
  String? _hubName;
  bool _isRunning = false;

  // Callbacks
  Function(String)? onNotification;
  Function(HubMessage, String)? onMessageReceived;
  Function()? onConnectionStateChanged;

  // Getters
  bool get isRunning => _isRunning;
  List<SpokeConnection> get connectedSpokes => _spokes.values.toList();
  int get spokeCount => _spokes.length;
  String? get hubAddress => _httpServer != null 
      ? '127.0.0.1:${_httpServer!.port}' // Simplified sync version
      : null;

  Future<String?> getHubAddressAsync() async {
    if (_httpServer == null) return null;
    final ip = await _getLocalIp();
    return '$ip:${_httpServer!.port}';
  }

  /// Start the hub server
  Future<bool> startHub(String hubName) async {
    if (_isRunning) {
      _notify('Hub already running');
      return true;
    }

    try {
      _hubId = _uuid.v4();
      _hubName = hubName;

      // Start WebSocket server
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      final port = _httpServer!.port;
      
      _notify('Hub started on port $port');

      // Start Bonsoir advertising
      final service = BonsoirService(
        name: 'P2PChords-$hubName-${_hubId!.substring(0, 4)}',
        type: serviceType,
        port: port,
      );

      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.ready;
      await _broadcast!.start();

      _notify('Hub advertising via Bonsoir');

      // Listen for connections
      _httpServer!.listen(_handleConnection);

      _isRunning = true;
      onConnectionStateChanged?.call();
      return true;
    } catch (e) {
      _notify('Error starting hub: $e');
      await stopHub();
      return false;
    }
  }

  /// Stop the hub server
  Future<void> stopHub() async {
    if (!_isRunning) return;

    _notify('Stopping hub...');

    // Disconnect all spokes
    for (final spoke in _spokes.values.toList()) {
      await _disconnectSpoke(spoke.id, notifySpoke: true);
    }
    _spokes.clear();

    // Stop Bonsoir
    if (_broadcast != null) {
      await _broadcast!.stop();
      _broadcast = null;
    }

    // Stop HTTP server
    await _httpServer?.close(force: true);
    _httpServer = null;

    _isRunning = false;
    _hubId = null;
    _hubName = null;

    onConnectionStateChanged?.call();
    _notify('Hub stopped');
  }

  /// Handle incoming WebSocket connection
  void _handleConnection(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    try {
      final socket = await WebSocketTransformer.upgrade(request);
      final channel = IOWebSocketChannel(socket); // FIXED: Use IOWebSocketChannel

      // Store channel temporarily for handshake
      WebSocketChannel? tempChannel = channel;

      // Wait for handshake
      final handshakeTimeout = Timer(const Duration(seconds: 5), () {
        tempChannel?.sink.close();
      });

      channel.stream.listen(
        (dynamic data) async {
          handshakeTimeout.cancel();
          
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final message = HubMessage.fromJson(json);

            if (message.type == MessageType.handshake) {
              await _handleHandshake(channel, message);
            } else {
              final spokeId = message.senderId;
              if (spokeId != null && _spokes.containsKey(spokeId)) {
                await _handleMessage(_spokes[spokeId]!, message);
              }
            }
          } catch (e) {
            _notify('Error processing message: $e');
          }
        },
        onDone: () => _handleDisconnect(channel),
        onError: (error) {
          _notify('WebSocket error: $error');
          _handleDisconnect(channel);
        },
        cancelOnError: true,
      );
    } catch (e) {
      _notify('Error handling connection: $e');
    }
  }

  /// Handle handshake from new spoke
  Future<void> _handleHandshake(
    WebSocketChannel channel,
    HubMessage message,
  ) async {
    final spokeName = message.payload['name'] as String?;
    final spokeId = message.payload['id'] as String? ?? _uuid.v4();

    if (spokeName == null) {
      await channel.sink.close();
      return;
    }

    // Create spoke connection
    final spoke = SpokeConnection(
      id: spokeId,
      name: spokeName,
      channel: channel,
    );

    _spokes[spokeId] = spoke;

    // Start health monitoring
    spoke.healthCheckTimer = Timer.periodic(healthCheckInterval, (_) {
      _checkSpokeHealth(spokeId);
    });

    // Send acknowledgment
    final ack = HubMessage(
      type: MessageType.handshakeAck,
      payload: {
        'hubId': _hubId,
        'hubName': _hubName,
        'connectedSpokes': _spokes.length,
      },
    );
    await spoke.send(ack.toJson());

    onConnectionStateChanged?.call();
    _notify('Spoke connected: $spokeName ($spokeId)');

    // Send ping immediately
    await _sendPing(spokeId);
  }

  /// Handle messages from spokes
  Future<void> _handleMessage(
    SpokeConnection spoke,
    HubMessage message,
  ) async {
    spoke.updatePing();

    switch (message.type) {
      case MessageType.pong:
        // Health check response
        break;

      case MessageType.stateUpdate:
      case MessageType.songData:
      case MessageType.metronomeUpdate:
      case MessageType.songDataRequest:
        onMessageReceived?.call(message, spoke.id);
        break;

      case MessageType.disconnect:
        await _disconnectSpoke(spoke.id);
        break;

      default:
        _notify('Unknown message type from ${spoke.name}: ${message.type}');
    }
  }

  /// Broadcast message to all spokes (except optionally one)
  Future<void> _broadcastMessage(
    HubMessage message, {
    String? excludeSpokeId,
  }) async {
    final messageMap = message.toJson();
    
    for (final spoke in _spokes.values) {
      if (spoke.id != excludeSpokeId) {
        try {
          await spoke.send(messageMap);
        } catch (e) {
          _notify('Error broadcasting to ${spoke.name}: $e');
          await _disconnectSpoke(spoke.id);
        }
      }
    }
  }

  /// Send message to specific spoke
  Future<bool> sendToSpoke(String spokeId, HubMessage message) async {
    final spoke = _spokes[spokeId];
    if (spoke == null) return false;

    try {
      await spoke.send(message.toJson());
      return true;
    } catch (e) {
      _notify('Error sending to ${spoke.name}: $e');
      await _disconnectSpoke(spokeId);
      return false;
    }
  }

  /// Broadcast message to all spokes (public API)
  Future<void> broadcast(HubMessage message) async {
    await _broadcastMessage(message);
  }

  /// Check spoke health and ping
  Future<void> _checkSpokeHealth(String spokeId) async {
    final spoke = _spokes[spokeId];
    if (spoke == null) return;

    if (!spoke.isHealthy) {
      _notify('Spoke ${spoke.name} timed out');
      await _disconnectSpoke(spokeId);
      return;
    }

    await _sendPing(spokeId);
  }

  /// Send ping to spoke
  Future<void> _sendPing(String spokeId) async {
    final ping = HubMessage(
      type: MessageType.ping,
      payload: {'timestamp': DateTime.now().toIso8601String()},
    );
    await sendToSpoke(spokeId, ping);
  }

  /// Handle spoke disconnect
  void _handleDisconnect(WebSocketChannel channel) {
    final spoke = _spokes.values
        .where((s) => s.channel == channel)
        .firstOrNull;
    
    if (spoke != null) {
      _disconnectSpoke(spoke.id);
    }
  }

  /// Disconnect a spoke
  Future<void> _disconnectSpoke(
    String spokeId, {
    bool notifySpoke = false,
  }) async {
    final spoke = _spokes.remove(spokeId);
    if (spoke == null) return;

    if (notifySpoke) {
      try {
        final message = HubMessage(
          type: MessageType.disconnect,
          payload: {'reason': 'Hub disconnecting spoke'},
        );
        await spoke.send(message.toJson());
      } catch (e) {
        // Ignore errors when disconnecting
      }
    }

    await spoke.disconnect();
    onConnectionStateChanged?.call();
    _notify('Spoke disconnected: ${spoke.name}');
  }

  /// Get local IP address
  Future<String> _getLocalIp() async {
    try {
      // FIXED: Use async list() instead of listSync()
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      _notify('Error getting local IP: $e');
    }
    return '127.0.0.1';
  }

  void _notify(String message) {
    print('HubService: $message');
    onNotification?.call(message);
  }

  Future<void> dispose() async {
    await stopHub();
  }
}