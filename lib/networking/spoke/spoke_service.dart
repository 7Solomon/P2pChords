import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/connection_models.dart';

class SpokeService {
  static final SpokeService _instance = SpokeService._internal();
  factory SpokeService() => _instance;
  SpokeService._internal();

  // Configuration
  static const String serviceType = '_p2pchords._tcp';
  static const Duration discoveryTimeout = Duration(seconds: 10);

  // State
  BonsoirDiscovery? _discovery;
  StreamSubscription? _discoverySubscription;
  WebSocketChannel? _connection;
  Timer? _pingTimer;
  
  final Map<String, DiscoveredHub> _discoveredHubs = {};
  String? _spokeId;
  String? _spokeName;
  String? _connectedHubId;
  bool _isDiscovering = false;
  bool _isConnected = false;

  final _uuid = const Uuid();

  // Callbacks
  Function(String)? onNotification;
  Function(HubMessage)? onMessageReceived;
  Function()? onConnectionStateChanged;
  Function(List<DiscoveredHub>)? onHubsDiscovered;

  // Getters
  bool get isDiscovering => _isDiscovering;
  bool get isConnected => _isConnected;
  List<DiscoveredHub> get discoveredHubs => _discoveredHubs.values.toList();
  String? get connectedHubId => _connectedHubId;

  /// Start discovering hubs
  Future<void> startDiscovery() async {
    if (_isDiscovering) {
      _notify('Already discovering');
      return;
    }

    try {
      _discoveredHubs.clear();
      
      _discovery = BonsoirDiscovery(type: serviceType);
      await _discovery!.ready;

      _discoverySubscription = _discovery!.eventStream!.listen((event) {
        if (event.service == null) return;

        if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
          event.service!.resolve(_discovery!.serviceResolver);
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
          _handleDiscoveredHub(event.service as ResolvedBonsoirService);
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
          _handleLostHub(event.service!);
        }
      });

      await _discovery!.start();
      _isDiscovering = true;
      _notify('Discovery started');
      onConnectionStateChanged?.call();

    } catch (e) {
      _notify('Error starting discovery: $e');
      await stopDiscovery();
    }
  }

  /// Stop discovering hubs
  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;

    await _discovery?.stop();
    await _discoverySubscription?.cancel();
    _discovery = null;
    _discoverySubscription = null;

    _isDiscovering = false;
    _notify('Discovery stopped');
    onConnectionStateChanged?.call();
  }

  /// Handle discovered hub
  void _handleDiscoveredHub(ResolvedBonsoirService service) {
    final hub = DiscoveredHub(
      id: _uuid.v4(),
      name: service.name,
      host: service.host!,
      port: service.port,
    );

    _discoveredHubs[hub.address] = hub;
    _notify('Discovered hub: ${hub.name} at ${hub.address}');
    
    onHubsDiscovered?.call(discoveredHubs);
    onConnectionStateChanged?.call();
  }

  /// Handle lost hub
  void _handleLostHub(BonsoirService service) {
    if (service is ResolvedBonsoirService) {
      final address = '${service.host}:${service.port}';
      _discoveredHubs.remove(address);
      _notify('Lost hub at $address');
      
      onHubsDiscovered?.call(discoveredHubs);
      onConnectionStateChanged?.call();
    }
  }

  /// Add hub manually (for manual IP entry)
  Future<bool> addManualHub(String host, int port, String name) async {
    final hub = DiscoveredHub(
      id: _uuid.v4(),
      name: name,
      host: host,
      port: port,
    );

    // Validate connection
    try {
      final wsUrl = 'ws://$host:$port';
      final testSocket = await WebSocket.connect(wsUrl)
          .timeout(const Duration(seconds: 5));
      await testSocket.close();
      
      hub.isValidated = true;
      _discoveredHubs[hub.address] = hub;
      
      _notify('Manually added hub: ${hub.name}');
      onHubsDiscovered?.call(discoveredHubs);
      onConnectionStateChanged?.call();
      
      return true;
    } catch (e) {
      _notify('Failed to validate hub at $host:$port: $e');
      return false;
    }
  }

  /// Connect to a hub
  Future<bool> connectToHub(DiscoveredHub hub, String spokeName) async {
    if (_isConnected) {
      _notify('Already connected to a hub');
      return false;
    }

    try {
      _spokeName = spokeName;
      _spokeId = _uuid.v4();

      final wsUrl = 'ws://${hub.host}:${hub.port}';
      final socket = await WebSocket.connect(wsUrl)
          .timeout(const Duration(seconds: 10));

      _connection = IOWebSocketChannel(socket);

      // Send handshake
      final handshake = HubMessage(
        type: MessageType.handshake,
        payload: {
          'id': _spokeId,
          'name': spokeName,
        },
      );
      _connection!.sink.add(jsonEncode(handshake.toJson()));

      // Listen for messages
      _connection!.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: (error) {
          _notify('Connection error: $error');
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      _connectedHubId = hub.id;
      _isConnected = true;
      _notify('Connected to hub: ${hub.name}');
      onConnectionStateChanged?.call();

      // Start ping timer
      _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _sendPong();
      });

      return true;
    } catch (e) {
      _notify('Error connecting to hub: $e');
      await disconnectFromHub();
      return false;
    }
  }

  /// Disconnect from hub
  Future<void> disconnectFromHub() async {
    if (!_isConnected) return;

    _notify('Disconnecting from hub');

    // Send disconnect message
    if (_connection != null) {
      try {
        final message = HubMessage(
          type: MessageType.disconnect,
          payload: {'reason': 'Spoke disconnecting'},
          senderId: _spokeId,
        );
        _connection!.sink.add(jsonEncode(message.toJson()));
      } catch (e) {
        // Ignore errors when disconnecting
      }
    }

    _pingTimer?.cancel();
    _pingTimer = null;

    await _connection?.sink.close();
    _connection = null;

    _isConnected = false;
    _connectedHubId = null;
    _spokeId = null;
    _spokeName = null;

    _notify('Disconnected from hub');
    onConnectionStateChanged?.call();
  }

  /// Handle incoming messages
  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      final message = HubMessage.fromJson(json);

      switch (message.type) {
        case MessageType.handshakeAck:
          _notify('Handshake acknowledged by hub');
          break;

        case MessageType.ping:
          _sendPong();
          break;

        case MessageType.disconnect:
          _notify('Hub requested disconnect');
          _handleDisconnect();
          break;

        case MessageType.stateUpdate:
          onMessageReceived?.call(message);
        case MessageType.songData:
          onMessageReceived?.call(message);
        case MessageType.metronomeUpdate:
          onMessageReceived?.call(message);
          break;

        default:
          _notify('Unknown message type: ${message.type}');
      }
    } catch (e) {
      _notify('Error handling message: $e');
    }
  }

  /// Handle disconnect
  void _handleDisconnect() {
    if (!_isConnected) return;
    
    _notify('Connection to hub lost');
    disconnectFromHub();
  }

  /// Send pong response
  void _sendPong() {
    if (!_isConnected || _connection == null) return;

    final pong = HubMessage(
      type: MessageType.pong,
      payload: {'timestamp': DateTime.now().toIso8601String()},
      senderId: _spokeId,
    );

    try {
      _connection!.sink.add(jsonEncode(pong.toJson()));
    } catch (e) {
      _notify('Error sending pong: $e');
    }
  }

  /// Send message to hub
  Future<bool> sendToHub(HubMessage message) async {
    if (!_isConnected || _connection == null) {
      _notify('Not connected to hub');
      return false;
    }

    try {
      final messageWithId = HubMessage(
        type: message.type,
        payload: message.payload,
        senderId: _spokeId,
      );
      _connection!.sink.add(jsonEncode(messageWithId.toJson()));
      return true;
    } catch (e) {
      _notify('Error sending message: $e');
      return false;
    }
  }

  void _notify(String message) {
    print('SpokeService: $message');
    onNotification?.call(message);
  }

  Future<void> dispose() async {
    await disconnectFromHub();
    await stopDiscovery();
  }
}