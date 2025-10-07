import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/networking/settings.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:P2pChords/dataManagment/provider/current_selection_provider.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/networking/hub/hub_service.dart';
import 'package:P2pChords/networking/spoke/spoke_service.dart';
import 'package:P2pChords/networking/models/connection_models.dart';
import 'package:flutter/material.dart';

enum UserRole { hub, spoke, none }

/// Simplified connection provider with clear hub-spoke model
class ConnectionProvider with ChangeNotifier {
  UserRole _userRole = UserRole.none;
  String _deviceName = 'User Device';

  // Hub-Spoke Services (replace old services)
  final HubService _hubService = HubService();
  final SpokeService _spokeService = SpokeService();

  // Data management
  final DataLoadeProvider _dataLoader;
  final CurrentSelectionProvider _currentSelectionProvider;

  // Simplified state - single source of truth
  final Set<String> _connectedDevices = {};

  ConnectionSettings _settings = ConnectionSettings();
  ConnectionSettings get settings => _settings;

  // Initialization
  ConnectionProvider({
    required DataLoadeProvider dataLoader,
    required CurrentSelectionProvider currentSelectionProvider,
  })  : _dataLoader = dataLoader,
        _currentSelectionProvider = currentSelectionProvider {
    _initializeServices();
    _loadSettings(); // Load saved settings on startup
  }

  void _initializeServices() {
    // Hub service callbacks
    _hubService.onNotification = (message) {
      SnackService().showInfo(message);
      notifyListeners();
    };

    _hubService.onMessageReceived = (message, spokeId) {
      _handleHubMessage(message, spokeId);
    };

    _hubService.onConnectionStateChanged = () {
      _updateConnectedDevices();
      notifyListeners();
    };

    // Spoke service callbacks
    _spokeService.onNotification = (message) {
      SnackService().showInfo(message);
      notifyListeners();
    };

    _spokeService.onMessageReceived = (message) {
      _handleSpokeMessage(message);
    };

    _spokeService.onConnectionStateChanged = () {
      notifyListeners();
    };

    _spokeService.onHubsDiscovered = (hubs) {
      notifyListeners();
    };
  }

  Future<void> _loadSettings() async {
    _settings = await ConnectionSettings.load();
    _deviceName = _settings.deviceName;
    
    // Auto-restore role if enabled
    if (_settings.autoReconnect && _settings.lastRole != null) {
      if (_settings.lastRole == 'hub') {
        await startAsHub();
      }
      // Note: Spoke auto-reconnect would need discovery first
    }
    
    notifyListeners();
  }

  // Getters
  UserRole get userRole => _userRole;
  String get deviceName => _deviceName;
  bool get isHub => _userRole == UserRole.hub;
  bool get isSpoke => _userRole == UserRole.spoke;
  
  // Hub-specific getters
  bool get isHubRunning => _hubService.isRunning;
  int get connectedSpokeCount => _hubService.spokeCount;
  List<SpokeConnection> get connectedSpokes => _hubService.connectedSpokes;
  String? get hubAddress => _hubService.hubAddress;

  // Spoke-specific getters
  bool get isDiscovering => _spokeService.isDiscovering;
  bool get isConnectedToHub => _spokeService.isConnected;
  List<DiscoveredHub> get discoveredHubs => _spokeService.discoveredHubs;
  
  Set<String> get connectedDevices => _connectedDevices;

  Future<String?> getHubAddressAsync() async {
    return await _hubService.getHubAddressAsync();
  }

  // Hub operations
  Future<bool> startAsHub() async {
    final success = await _hubService.startHub(_deviceName);
    if (success) {
      _userRole = UserRole.hub;
      await _saveRoleToSettings('hub');
      notifyListeners();
    }
    return success;
  }

  Future<void> stopHub() async {
    await _hubService.stopHub();
    _userRole = UserRole.none;
    await _saveRoleToSettings(null);
    _connectedDevices.clear();
    notifyListeners();
  }

  Future<void> broadcastToSpokes(HubMessage message) async {
    if (_userRole != UserRole.hub) return;
    await _hubService.broadcast(message);
  }

  // Spoke operations
  Future<void> startDiscovery() async {
    if (_userRole == UserRole.hub) {
      await stopHub();
    }

    _userRole = UserRole.spoke;
    await _spokeService.startDiscovery();
    notifyListeners();
  }

  Future<void> stopDiscovery() async {
    await _spokeService.stopDiscovery();
    if (!_spokeService.isConnected) {
      _userRole = UserRole.none;
    }
    notifyListeners();
  }

  Future<bool> connectToHub(DiscoveredHub hub) async {
    final success = await _spokeService.connectToHub(hub, _deviceName);
    if (success) {
      _userRole = UserRole.spoke;
      _settings.lastHubAddress = hub.address;
      await _saveRoleToSettings('spoke');
      notifyListeners();
    }
    return success;
  }

  Future<void> disconnectFromHub() async {
    await _spokeService.disconnectFromHub();
    _userRole = UserRole.none;
    await _saveRoleToSettings(null);
    notifyListeners();
  }

  Future<bool> addManualHub(String host, int port, String name) async {
    return await _spokeService.addManualHub(host, port, name);
  }

  Future<void> sendToHub(HubMessage message) async {
    if (_userRole != UserRole.spoke) return;
    await _spokeService.sendToHub(message);
  }

  // Message handlers
  void _handleHubMessage(HubMessage message, String spokeId) {
    switch (message.type) {
      case MessageType.stateUpdate:
        _currentSelectionProvider.fromJson(message.payload);
        // Broadcast to other spokes
        _hubService.broadcast(message);
        break;

      case MessageType.songData:
        final songData = SongData.fromMap(message.payload);
        _dataLoader.addSongsData(songData);
        // Broadcast to other spokes
        _hubService.broadcast(message);
        break;

      default:
        debugPrint('Unhandled hub message: ${message.type}');
    }
  }

  void _handleSpokeMessage(HubMessage message) {
    switch (message.type) {
      case MessageType.stateUpdate:
        _currentSelectionProvider.fromJson(message.payload);
        break;

      case MessageType.songData:
        final songData = SongData.fromMap(message.payload);
        _dataLoader.addSongsData(songData);
        break;

      default:
        debugPrint('Unhandled spoke message: ${message.type}');
    }
  }

  void _updateConnectedDevices() {
    _connectedDevices.clear();
    if (_userRole == UserRole.hub) {
      for (final spoke in _hubService.connectedSpokes) {
        _connectedDevices.add(spoke.id);
      }
    }
  }

  // High-level sync methods (for your existing code)
  Future<void> sendSongDataToAll(SongData songData) async {
    if (_userRole == UserRole.hub) {
      final message = HubMessage(
        type: MessageType.songData,
        payload: songData.toMap(),
      );
      await _hubService.broadcast(message);
    } else if (_userRole == UserRole.spoke) {
      final message = HubMessage(
        type: MessageType.songData,
        payload: songData.toMap(),
      );
      await _spokeService.sendToHub(message);
    }
  }

  Future<void> sendStateUpdate(Map<String, dynamic> state) async {
    if (_userRole == UserRole.hub) {
      final message = HubMessage(
        type: MessageType.stateUpdate,
        payload: state,
      );
      await _hubService.broadcast(message);
    } else if (_userRole == UserRole.spoke) {
      final message = HubMessage(
        type: MessageType.stateUpdate,
        payload: state,
      );
      await _spokeService.sendToHub(message);
    }
  }

  Future<void> sendCurrentSelectionToAll() async {
    await sendStateUpdate(_currentSelectionProvider.toJson());
  }

  void setDeviceName(String name) {
    _deviceName = name;
    notifyListeners();
  }

  Future<void> updateDeviceName(String name) async {
    _deviceName = name;
    _settings.deviceName = name;
    await _settings.save();
    notifyListeners();
  }

  Future<void> _saveRoleToSettings(String? role) async {
    _settings.lastRole = role;
    await _settings.save();
  }

  @override
  void dispose() {
    _hubService.dispose();
    _spokeService.dispose();
    super.dispose();
  }
}