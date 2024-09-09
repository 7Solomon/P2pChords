import 'dart:convert';

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
