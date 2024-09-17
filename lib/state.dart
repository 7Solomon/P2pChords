import 'dart:convert';

import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

enum UserState { server, client, none }

enum SenderType { ble, wifi, none }

class GlobalMode with ChangeNotifier {
  UserState _userState = UserState.none; // Default mode
  SenderType _senderType = SenderType.none; // Default mode

  // Getter for UserState
  UserState get userState => _userState;

  // Getter for SenderType
  SenderType get senderType => _senderType;

  // Setter for UserState
  void setUserState(UserState userState) {
    _userState = userState;
    notifyListeners(); // Notify listeners to update the UI
  }

  // Setter for SenderType
  void setSenderType(SenderType senderType) {
    _senderType = senderType;
    notifyListeners(); // Notify listeners to update the UI
  }
}

class GlobalUserIds extends ChangeNotifier {
  final Set<String> _connectedDeviceIds = {};
  String? _connectedServerId;

  Set<String> get connectedDeviceIds => _connectedDeviceIds;
  String? get connectedServerId => _connectedServerId;

  void addConnectedDevice(String id) {
    _connectedDeviceIds.add(id);
    notifyListeners();
  }

  void removeConnectedDevice(String id) {
    _connectedDeviceIds.remove(id);
    notifyListeners();
  }

  void setConnectedServerId(String? id) {
    _connectedServerId = id;
    notifyListeners();
  }

  void clearAll() {
    _connectedDeviceIds.clear();
    _connectedServerId = null;
    notifyListeners();
  }
}

class GlobalName with ChangeNotifier {
  String _name = 'undefined';

  String get name => _name;

  void defineName(String name) {
    _name = name;
    notifyListeners();
  }
}

/*
class SongProvider with ChangeNotifier {
  String _currentSongHash = 'none';
  String _currentGroup = 'none';
  int _currentSection1 = 0;
  int _currentSection2 = 1;

  String get currentSongHash => _currentSongHash;
  String get currentGroup => _currentGroup;
  int get currentSection1 => _currentSection1;
  int get currentSection2 => _currentSection2;

  void updateSongHash(String currentSongHash, {bool notify = true}) {
    _currentSongHash = currentSongHash;
    if (notify) notifyListeners();
  }

  void updateGroup(String currentGroup, {bool notify = true}) {
    _currentGroup = currentGroup;
    if (notify) notifyListeners();
  }

  void updateSections(int section1, int section2, {bool notify = true}) {
    _currentSection1 = section1;
    _currentSection2 = section2;
    if (notify) notifyListeners();
  }

  void receiveSections(String data) {
    var sections = json.decode(data);
    updateSections(sections['section1'], sections['section2'], notify: true);
  }
}
*/
class NearbyMusicSyncProvider with ChangeNotifier {
  final Nearby _nearby = Nearby();
  String _currentGroup = '';
  String _currentSongHash = '';
  int _currentSection1 = 0;
  int _currentSection2 = 1;
  UserState _userState = UserState.none;
  bool _isServerDevice = false;
  Set<String> _connectedDeviceIds = {};

  String get currentGroup => _currentGroup;
  String get currentSongHash => _currentSongHash;
  int get currentSection1 => _currentSection1;
  int get currentSection2 => _currentSection2;
  bool get isServerDevice => _isServerDevice;
  UserState get userState => _userState;
  Set<String> get connectedDeviceIds => _connectedDeviceIds;

  void setAsServerDevice(bool isServer) {
    _isServerDevice = isServer;
    _userState = isServer ? UserState.server : UserState.client;
    notifyListeners();
  }

  Future<bool> startAdvertising(String name,
      Function(String, ConnectionInfo) onConnectionInitiated) async {
    try {
      bool advertisingResult = await _nearby.startAdvertising(
        name,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: onConnectionInitiated,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            _connectedDeviceIds.add(id);

            notifyListeners();
          }
        },
        onDisconnected: (id) {
          _connectedDeviceIds.remove(id);
          notifyListeners();
        },
      );
      return advertisingResult;
    } catch (e) {
      print('Error starting advertising: $e');
      return false;
    }
  }

  Future<bool> startDiscovery(
      String name, Function(String, String, String) onEndpointFound) async {
    try {
      bool discoveryResult = await _nearby.startDiscovery(
        name,
        Strategy.P2P_CLUSTER,
        onEndpointFound: onEndpointFound,
        onEndpointLost: (id) {
          _connectedDeviceIds.remove(id);
          notifyListeners();
        },
      );
      return discoveryResult;
    } catch (e) {
      print('Error starting discovery: $e');
      return false;
    }
  }

  Future<bool> requestConnection(String name, String id,
      Function(String, ConnectionInfo) onConnectionInitiated) async {
    try {
      bool result = await _nearby.requestConnection(
        name,
        id,
        onConnectionInitiated: onConnectionInitiated,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            _connectedDeviceIds.add(id);
            notifyListeners();
          }
        },
        onDisconnected: (id) {
          _connectedDeviceIds.remove(id);
          notifyListeners();
        },
      );
      return result;
    } catch (e) {
      print('Error requesting connection: $e');
      return false;
    }
  }

  void handleIncomingMessage(String message) {
    try {
      Map<String, dynamic> data = json.decode(message);
      switch (data['type']) {
        case 'songWechsel':
          _currentSongHash = data['content'];
          break;
        case 'sectionWechsel':
          _currentSection1 = data['content']['section1'];
          _currentSection1 = data['content']['section2'];
          break;
        case 'groupData':
          _currentGroup = data['content']['group'];
          MultiJsonStorage.saveJsonsGroup(
              data['content']['group'], data['content']['songs']);
          break;
      }
      notifyListeners();
    } catch (e) {
      print('Error handling incoming message: $e');
    }
  }

  Future<bool> updateSongAndSection(
      String songHash, int section1, int section2) async {
    if (_userState == UserState.server || _userState == UserState.none) {
      _currentSongHash = songHash;
      _currentSection1 = section1;
      _currentSection2 = section2;
      return _sendUpdateToClients();
    }
    return false;
  }

  Future<bool> updateGroup(String group) async {
    if (_userState == UserState.server || _userState == UserState.none) {
      _currentGroup = group;
      return true;
    }
    return false;
  }

  Future<bool> _sendUpdateToClients() async {
    Map<String, dynamic> data = {
      'type': 'update',
      'content': {
        'songHash': _currentSongHash,
        'section1': _currentSection1,
        'section1': _currentSection2,
      }
    };
    return _sendDataToAll(data);
  }

  Future<bool> sendGroupData(
      String group, Map<String, dynamic> groupSongData) async {
    Map<String, dynamic> data = {
      'type': 'groupData',
      'content': {
        'group': group,
        'songs': groupSongData,
      }
    };
    return _sendDataToAll(data);
  }

  Future<bool> _sendDataToAll(Map<String, dynamic> data) async {
    try {
      final bytes = Uint8List.fromList(json.encode(data).codeUnits);
      await _nearby.sendBytesPayload('*', bytes);
      return true;
    } catch (e) {
      print('Error sending data to all devices: $e');
      return false;
    }
  }
}
