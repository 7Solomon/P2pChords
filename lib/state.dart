import 'dart:convert';
import 'dart:math';

import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/metronome/test.dart';
import 'package:P2pChords/uiSettings.dart';
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
  final UiSettings _uiSettings = UiSettings();

  UserState _userState = UserState.none;
  bool _isServerDevice = false;
  Set<String> _connectedDeviceIds = {};

  void Function(String) _displaySnack = (_) {};
  void Function(int bpm, bool isPlaying, int tickCount)?
      onMetronomeUpdateReceived;

  String get name => _name;

  bool get isServerDevice => _isServerDevice;
  UserState get userState => _userState;
  Set<String> get connectedDeviceIds => _connectedDeviceIds;
  void Function(String) get displaySnack => _displaySnack;
  Function get sendDataToAll => _sendDataToAll;

  void defineName(String name) {
    _name = name;
    notifyListeners();
  }

  void updateDisplaySnack(void Function(String) newDisplaySnack) {
    _displaySnack = newDisplaySnack;
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
      _displaySnack("Starting advertising as: $_name");

      bool advertisingResult = await _nearby.startAdvertising(
        _name,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: (id, info) {
          _displaySnack("Connection initiated with $id (${info.endpointName})");
          onConnectionInitiated(id, info);
        },
        onConnectionResult: (id, status) {
          _displaySnack("Connection result for $id: $status");
          if (status == Status.CONNECTED) {
            _connectedDeviceIds.add(id);
            _displaySnack("Successfully connected to $id");
            notifyListeners();
          } else if (status == Status.REJECTED) {
            _displaySnack("Connection rejected by $id");
          } else if (status == Status.ERROR) {
            _displaySnack("Error connecting to $id");
          }
        },
        onDisconnected: (id) {
          _displaySnack("Disconnected from $id");
          _connectedDeviceIds.remove(id);
          notifyListeners();
        },
      );

      _displaySnack(advertisingResult
          ? "Successfully started advertising"
          : "Failed to start advertising");
      return advertisingResult;
    } catch (e, stackTrace) {
      if (e.toString().contains('STATUS_ALREADY_ADVERTISING')) {
        // Maybe ich muss ändern ?
        // Handle the "already advertising" case
        _displaySnack("Already advertising");
        return false;
      } else {
        // Handle any other errors
        _displaySnack('Error starting advertising: $e\n$stackTrace');
        return false;
      }
    }
  }

  Future<bool> startDiscovery(
      Function(String, String, String) onEndpointFound) async {
    try {
      _displaySnack("Starting discovery as: $_name");

      bool discoveryResult = await _nearby.startDiscovery(
        _name,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, serviceId) {
          _displaySnack("Found endpoint: $id ($name)");
          onEndpointFound(id, name, serviceId);
        },
        onEndpointLost: (id) {
          _displaySnack("Lost endpoint: $id");
          _connectedDeviceIds.remove(id);
          notifyListeners();
        },
      );

      _displaySnack(discoveryResult
          ? "Successfully started discovery"
          : "Failed to start discovery");
      return discoveryResult;
    } catch (e, stackTrace) {
      _displaySnack('Error starting discovery: $e\n$stackTrace');
      return false;
    }
  }

  void onConnectionInitiated(String id, ConnectionInfo info) {
    _displaySnack("Accepting connection from $id (${info.endpointName})");

    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String message = String.fromCharCodes(payload.bytes!);
          _displaySnack(
              "Received payload from $endid: ${message.substring(0, min(50, message.length))}...");
          handleIncomingMessage(message);
        }
      },
    ).catchError((e) {
      _displaySnack("Error accepting connection: $e");
    });

    if (_isServerDevice && _uiSettings.currentGroup.isNotEmpty) {
      _displaySnack("Sending current group data to new device $id");
      //sendGroupData(id);
    }
  }

  Future<bool> requestConnection(String id) async {
    try {
      _displaySnack("Requesting connection to $id");

      bool result = await _nearby.requestConnection(
        _name,
        id,
        onConnectionInitiated: (id, info) {
          _displaySnack(
              "Connection initiated by request with $id (${info.endpointName})");
          onConnectionInitiatedByRequest(id, info);
        },
        onConnectionResult: (id, status) {
          _displaySnack("Connection result for request to $id: $status");
          if (status == Status.CONNECTED) {
            _connectedDeviceIds.add(id);
            notifyListeners();
          }
        },
        onDisconnected: (id) {
          _displaySnack("Disconnected from requested connection $id");
          _connectedDeviceIds.remove(id);
          notifyListeners();
        },
      );

      return result;
    } catch (e, stackTrace) {
      _displaySnack('Error requesting connection: $e\n$stackTrace');
      return false;
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

  void handleIncomingMessage(String message) {
    print('Did receive: $message');
    try {
      Map<String, dynamic> data = json.decode(message);
      displaySnack("Received message: ${data['type']}");
      switch (data['type']) {
        case 'update':
          Map sectionData = data['content']['sectionData'];
          int index = data['content']['index'];
          _uiSettings.setUiSectionDataAndIndex(sectionData, index);
        case 'groupData':
          MultiJsonStorage.saveJsonsGroup(
              data['content']['group'], data['content']['songs']);
          _uiSettings.setCurrentGroup(data['content']['group']);
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

  Future<bool> sendUpdateToClients(Map sectionData, int index) async {
    Map<String, dynamic> data = {
      'type': 'update',
      'content': {
        'sectionData': sectionData,
        'index': index
      } // Index braucht man eigentlich nicht. Aber why not
    };
    print(data);
    return _sendDataToAll(data);
  }

  Future<bool> sendCurrentGroupDataToIdDevice(String id) async {
    Map<String, dynamic> groupSongData =
        await MultiJsonStorage.loadJsonsFromGroup(_uiSettings.currentGroup);
    Map<String, dynamic> data = {
      'type': 'groupData',
      'content': {
        'group': _uiSettings.currentGroup,
        'songs': groupSongData,
      }
    };

    return sendDataToDevice(id, data);
  }

  Future<bool> sendSongsDataMap(Map dataMap) {
    Map<String, dynamic> data = {
      'type': 'groupData',
      'content': {
        'group': _uiSettings.currentGroup,
        'songs': dataMap,
      }
    };
    return _sendDataToAll(data);
  }

  Future<bool> sendGroupData(
      String groupName, Map<String, dynamic> groupSongData) async {
    Map<String, dynamic> data = {
      'type': 'groupData',
      'content': {
        'group': groupName,
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
    bool allSuccess = true; // Start by assuming success

    try {
      for (String id in _connectedDeviceIds) {
        bool result = await sendDataToDevice(id, data);
        if (!result) {
          allSuccess = false;
          _displaySnack('Error sending data to device with id: $id');
        }
      }
      return allSuccess;
    } catch (e) {
      _displaySnack('Error sending data to all devices: $e');
      return false;
    }
  }
}
