import 'dart:convert';
import 'dart:math';

import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/metronome/test.dart';
import 'package:P2pChords/UiSettings/page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

enum UserState { server, client, none }

class NearbyMusicSyncProvider with ChangeNotifier {
  String _name = 'Joe Mo';
  Set<String> _connectedDeviceIds = {};
  final Nearby _nearby = Nearby();
  late CurrentSelectionProvider _currentSectionProvider;
  late DataLoadeProvider _dataLoader;

  UserState _userState = UserState.none;

  void Function(String) _displaySnack = (_) {};

  String get name => _name;

  UserState get userState => _userState;
  Set<String> get connectedDeviceIds => _connectedDeviceIds;
  void Function(String) get displaySnack => _displaySnack;
  Function get sendDataToAll => _sendDataToAll;

  void init(BuildContext context) {
    _currentSectionProvider =
        Provider.of<CurrentSelectionProvider>(context, listen: false);
    _dataLoader = Provider.of<DataLoadeProvider>(context, listen: false);
  }

  void defineName(String name) {
    _name = name;
    notifyListeners();
  }

  void updateDisplaySnack(void Function(String) newDisplaySnack) {
    _displaySnack = newDisplaySnack;
    notifyListeners();
  }

  void setUserState(UserState state) {
    _userState = state;

    // Delay the notifyListeners() call until after the current frame. vielliecht nicht nötig
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
            //_isAdvertising = false;
            notifyListeners();
          } else if (status == Status.REJECTED) {
            _displaySnack("Connection rejected by $id");
            //_isAdvertising = false;
          } else if (status == Status.ERROR) {
            _displaySnack("Error connecting to $id");
            //_isAdvertising = false;
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
      _displaySnack('Error starting advertising: $e\n$stackTrace');
      return false;
    }
  }

  Future<bool> startDiscovery(
      Function(String, String, String) onEndpointFound) async {
    //if (!_isDiscovering) {
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
    //} else {
    //  _displaySnack("Already discovering");
    //  return false;
    //}
  }

  void onConnectionInitiated(String id, ConnectionInfo info) {
    _displaySnack("Accepting connection from $id (${info.endpointName})");

    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String message = String.fromCharCodes(payload.bytes!);
          //_displaySnack(
          //    "Received payload from $endid: ${message.substring(0, min(50, message.length))}...");
          handleIncomingMessage(message);
        }
      },
    ).catchError((e) {
      _displaySnack("Error accepting connection: $e");
    });

    if (_userState == UserState.server) {
      if (_currentSectionProvider.currentGroup != null) {
        _displaySnack("Sending current group data to new device $id");
        sendSongDataToClient(
            id, _dataLoader.getSongData(_currentSectionProvider.currentGroup!));
      }
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
    try {
      Map<String, dynamic> data = json.decode(message.trim());
      displaySnack("Received message: ${data['type']}");

      switch (data['type']) {
        case 'update':
          Map<String, dynamic> updateContent =
              data['content'] as Map<String, dynamic>;
          _currentSectionProvider.fromJson(updateContent);
        case 'songData':
          SongData songData = SongData.fromMap(data['content']['songData']);
          MultiJsonStorage.saveSongsData(songData);
          break;
        case 'metronomeUpdate':
          //handleMetronomeUpdate(data);
          break;
      }
      notifyListeners();
    } catch (e) {
      _displaySnack('Error handling incoming message: $e');
    }
  }

  Future<bool> sendUpdateToClients(Map updateData) async {
    Map<String, dynamic> data = {'type': 'update', 'content': updateData};
    return _sendDataToAll(data);
  }

  Future<bool> sendSongDataToClients(SongData songData) async {
    Map<String, dynamic> data = {
      'type': 'songData',
      'content': {
        'songData': songData,
      }
    };
    return _sendDataToAll(data);
  }

  Future<bool> sendUpdateToClient(String deviceId, Map updateData) {
    Map<String, dynamic> data = {'type': 'update', 'content': updateData};
    return _sendDataToDevice(deviceId, data);
  }

  Future<bool> sendSongDataToClient(String deviceId, SongData songData) async {
    Map<String, dynamic> data = {
      'type': 'songData',
      'content': {
        'songData': songData,
      }
    };
    return _sendDataToDevice(deviceId, data);
  }

  Future<bool> _sendDataToDevice(
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
        bool result = await _sendDataToDevice(id, data);
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
