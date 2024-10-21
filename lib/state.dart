import 'dart:convert';

import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/metronome/test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

enum UserState { server, client, none }

//enum SenderType { ble, wifi, none }

class NearbyMusicSyncProvider with ChangeNotifier {
  String _name = 'undefined';
  final Nearby _nearby = Nearby();
  String _currentGroup = '';
  String _currentSongHash = '';
  int _currentSection1 = 0;
  int _currentSection2 = 1;
  UserState _userState = UserState.none;
  bool _isServerDevice = false;
  Set<String> _connectedDeviceIds = {};

  void Function(String) _displaySnack = (String message) {
    //print(message);
  };
  void Function(int bpm, bool isPlaying, int tickCount)?
      onMetronomeUpdateReceived;

  String get name => _name;
  String get currentGroup => _currentGroup;
  String get currentSongHash => _currentSongHash;
  int get currentSection1 => _currentSection1;
  int get currentSection2 => _currentSection2;
  bool get isServerDevice => _isServerDevice;
  UserState get userState => _userState;
  Set<String> get connectedDeviceIds => _connectedDeviceIds;
  void Function(String) get displaySnack => _displaySnack;
  Function get sendDataToAll => _sendDataToAll;

  void defineName(String name) {
    _name = name;
    notifyListeners();
  }

  void setAsServerDevice(bool isServer) {
    _isServerDevice = isServer;
    _userState = isServer ? UserState.server : UserState.client;

    // Delay the notifyListeners() call until after the current frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> checkPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    final allGranted = statuses.values.every((status) => status.isGranted);
    _displaySnack(allGranted
        ? "All permissions granted"
        : "Some permissions were denied");
  }

  Future<bool> startAdvertising() async {
    try {
      bool advertisingResult = await _nearby.startAdvertising(
        _name,
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
      _displaySnack('Error starting advertising: $e');
      return false;
    }
  }

  Future<bool> startDiscovery(
      Function(String, String, String) onEndpointFound) async {
    try {
      bool discoveryResult = await _nearby.startDiscovery(
        _name,
        Strategy.P2P_CLUSTER,
        onEndpointFound: onEndpointFound,
        onEndpointLost: (id) {
          _connectedDeviceIds.remove(id);
          notifyListeners();
        },
      );
      return discoveryResult;
    } catch (e) {
      _displaySnack('Error starting discovery: $e');
      return false;
    }
  }

  void onConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String message = String.fromCharCodes(payload.bytes!);
          handleIncomingMessage(message);
        }
      },
    );
    if (_isServerDevice && _currentGroup.isNotEmpty) {
      sendCurrentGroupDataToIdDevice(id);
    }
  }

  void onConnectionInitiatedByRequest(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String message = String.fromCharCodes(payload.bytes!);
          handleIncomingMessage(message);
        }
      },
    );
  }

  Future<bool> requestConnection(String id) async {
    try {
      bool result = await _nearby.requestConnection(
        _name,
        id,
        onConnectionInitiated: onConnectionInitiatedByRequest,
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
      _displaySnack('Error requesting connection: $e');
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
        case 'metronomeUpdate':
          handleMetronomeUpdate(data);
          break;
      }
      notifyListeners();
    } catch (e) {
      _displaySnack('Error handling incoming message: $e');
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
        'section2': _currentSection2,
      }
    };
    return _sendDataToAll(data);
  }

  Future<bool> sendCurrentGroupDataToIdDevice(String id) async {
    Map<String, dynamic> groupSongData =
        await MultiJsonStorage.loadJsonsFromGroup(_currentGroup);
    Map<String, dynamic> data = {
      'type': 'groupData',
      'content': {
        'group': _currentGroup,
        'songs': groupSongData,
      }
    };
    return sendDataToDevice(id, data);
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

  Future<bool> sendDataToDevice(
      String deviceId, Map<String, dynamic> data) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(json.encode(data)));
      await _nearby.sendBytesPayload(deviceId, bytes);
      _displaySnack('Data sent successfully to device: $deviceId');
      return true;
    } catch (e) {
      _displaySnack('Error sending data to device $deviceId: $e');
      return false;
    }
  }

  Future<bool> _sendDataToAll(Map<String, dynamic> data) async {
    try {
      final bytes = Uint8List.fromList(json.encode(data).codeUnits);
      await _nearby.sendBytesPayload('*', bytes);
      return true;
    } catch (e) {
      _displaySnack('Error sending data to all devices: $e');
      return false;
    }
  }
}
