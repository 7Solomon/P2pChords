import 'dart:developer';
import 'dart:typed_data';

import 'package:P2pChords/networking/services/data_sync_service.dart';
import 'package:P2pChords/networking/services/message_handler_service.dart';
import 'package:P2pChords/networking/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nearby_connections/nearby_connections.dart';

import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/networking/services/permission_service.dart';
import 'package:P2pChords/networking/nearby_service.dart';
import 'package:P2pChords/networking/websocket_service.dart';

enum UserState { server, client, pc, none }

enum ConnectionMode { nearby, webSocket, hybrid }

class CustomeService {
  // Device Information
  Set<String> connectedDeviceIds = {};
  Set<String> visibleDevices = {};
  Set<String> knownDevices = {};

  // State
  bool isServerRunning = false;
  bool isAdvertising = false;
  bool isDiscovering = false;

  // Callbacks for Service
  late Function(SongData) sendSongData;
  late Function(Map<String, dynamic>) sendUpdate;

  // Server functionality
  Future<bool> startServer() async => throw UnimplementedError();
  Future<bool> stopServer() async => throw UnimplementedError();

  // Client functionality
  Future<bool> startClient() async => throw UnimplementedError();
  Future<bool> stopClient() async => throw UnimplementedError();
  Future<bool> connectToServer(String serverId) async =>
      throw UnimplementedError();
}

// Unified connection provider that manages all connection types
class ConnectionProvider with ChangeNotifier {
  UserState _userState = UserState.none;
  ConnectionMode _connectionMode = ConnectionMode.nearby;
  String _deviceName = 'User Device';

  // Connection Modes
  final NearbyService nearbyService = NearbyService();
  final WebSocketService webSocketService = WebSocketService();

  // Data management
  final DataLoadeProvider _dataLoader;
  final CurrentSelectionProvider _currentSelectionProvider;

  // Manager Services
  final DataSyncService _dataSyncService = DataSyncService();
  final MessageHandlerService _messageHandlerService = MessageHandlerService();
  final NotificationService _notificationService = NotificationService();
  final PermissionService _permissionService = PermissionService();

  // Initialization
  ConnectionProvider({
    required DataLoadeProvider dataLoader,
    required CurrentSelectionProvider currentSelectionProvider,
  })  : _dataLoader = dataLoader,
        _currentSelectionProvider = currentSelectionProvider {
    _initializeServiceCallbacks();
    _initializeDataSyncServiceCallbacks();
    _initializeMessageHandlerServiceCallbacks();
  }

  void _initializeServiceCallbacks() {
    if (_connectionMode == ConnectionMode.nearby ||
        _connectionMode == ConnectionMode.hybrid) {
      nearbyService.userNickName = _deviceName;

      // Callbacks
      nearbyService.onNotification = (message) {
        _notificationService.showInfo(message);
      };
      nearbyService.onPayloadReceived = (endpointId, payload) {
        _messageHandlerService.handlePayload(endpointId, payload);
      };
    }
    if (_connectionMode == ConnectionMode.webSocket ||
        _connectionMode == ConnectionMode.hybrid) {
      webSocketService.userNickName = _deviceName;

      // Callbacks
      webSocketService.onNotification = (message) {
        _notificationService.showInfo(message);
      };
      webSocketService.onPayloadReceived = (message) {
        _messageHandlerService.handleIncomingMessage(message);
      };
    }
  }

  void _initializeDataSyncServiceCallbacks() {
    if (_connectionMode == ConnectionMode.nearby ||
        _connectionMode == ConnectionMode.hybrid) {
      // notification
      _dataSyncService.onNotification = _notificationService.showInfo;

      // Send Payload
      _dataSyncService.sendBytesPayload = nearbyService.sendBytesPayload;

      // Connected Devices
      _dataSyncService.connectedDeviceIds = nearbyService.connectedDeviceIds;
    }
    if (_connectionMode == ConnectionMode.webSocket ||
        _connectionMode == ConnectionMode.hybrid) {
      // Send Payload
      _dataSyncService.sendBytesPayload = webSocketService.sendBytesPayload;

      // Connected Devices
      _dataSyncService.connectedDeviceIds = webSocketService.connectedDeviceIds;
    }
  }

  void _initializeMessageHandlerServiceCallbacks() {
    _messageHandlerService.onNotification = _notificationService.showInfo;

    _messageHandlerService.onUpdateMessage = (updateData) {
      _currentSelectionProvider.fromJson(updateData);
    };

    _messageHandlerService.onSongDataMessage = (songData) {
      _dataLoader.saveDataToStorage(songData);
    };
  }

  // Getters
  UserState get userState => _userState;
  ConnectionMode get connectionMode => _connectionMode;
  String get deviceName => _deviceName;
  Set<String> get connectedDeviceIds {
    return {
      ...nearbyService.connectedDeviceIds,
      ...webSocketService.connectedDeviceIds
    };
  }

  // Server State Getter
  bool get isServerRunning {
    switch (_connectionMode) {
      case ConnectionMode.nearby:
        return nearbyService.isServerRunning;
      case ConnectionMode.webSocket:
        return webSocketService.isServerRunning;
      case ConnectionMode.hybrid:
        return nearbyService.isServerRunning &&
            webSocketService.isServerRunning;
    }
  }

  bool get isAdvertising {
    switch (_connectionMode) {
      case ConnectionMode.nearby:
        return nearbyService.isAdvertising;
      case ConnectionMode.webSocket:
        return webSocketService.isAdvertising;
      case ConnectionMode.hybrid:
        return nearbyService.isAdvertising && webSocketService.isAdvertising;
    }
  }

  bool get isDiscovering {
    switch (_connectionMode) {
      case ConnectionMode.nearby:
        return nearbyService.isDiscovering;
      case ConnectionMode.webSocket:
        return webSocketService.isDiscovering;
      case ConnectionMode.hybrid:
        return nearbyService.isDiscovering && webSocketService.isDiscovering;
    }
  }

  // LowLevel Getter
  DataSyncService get dataSyncService => _dataSyncService;
  MessageHandlerService get messageHandlerService => _messageHandlerService;
  NotificationService get notificationService => _notificationService;

  // Connection management
  Future<bool> checkPermissions() async {
    return await _permissionService.requestPermissions(
        onMessage: _notificationService.showInfo);
  }

  void setDeviceName(String name) {
    _deviceName = name;
    notifyListeners();
  }

  void setUserState(UserState state) {
    _userState = state;
    notifyListeners();
  }

  void setConnectionMode(ConnectionMode mode) {
    _connectionMode = mode;
    _initializeServiceCallbacks();
    _initializeDataSyncServiceCallbacks();
    notifyListeners();
  }

  void setServerRunning(bool isRunning) {
    switch (_connectionMode) {
      case ConnectionMode.nearby:
        nearbyService.isServerRunning = isRunning;
      case ConnectionMode.webSocket:
        webSocketService.isServerRunning = isRunning;
      case ConnectionMode.hybrid:
        nearbyService.isServerRunning = isRunning;
        webSocketService.isServerRunning = isRunning;
    }
    notifyListeners();
  }

  void setDiscovering(bool isDiscovering) {
    switch (_connectionMode) {
      case ConnectionMode.nearby:
        nearbyService.isDiscovering = isDiscovering;
      case ConnectionMode.webSocket:
        webSocketService.isDiscovering = isDiscovering;
      case ConnectionMode.hybrid:
        nearbyService.isDiscovering = isDiscovering;
        webSocketService.isDiscovering = isDiscovering;
    }
    notifyListeners();
  }

  void setAdvertising(bool isAdvertising) {
    switch (_connectionMode) {
      case ConnectionMode.nearby:
        nearbyService.isAdvertising = isAdvertising;
      case ConnectionMode.webSocket:
        webSocketService.isAdvertising = isAdvertising;
      case ConnectionMode.hybrid:
        nearbyService.isAdvertising = isAdvertising;
        webSocketService.isAdvertising = isAdvertising;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    //_dataSyncService.dispose();
    //_messageHandlerService.dispose();
    //_notificationService.dispose();
    //_permissionService.dispose();
    super.dispose();
  }
}
