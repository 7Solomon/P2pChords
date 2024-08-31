import 'package:flutter/foundation.dart';

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
  Set<String> _connectedDeviceIds = {};
  String? _connectedServerId;

  List<String> _receivedMessages = [];

  Set<String> get connectedDeviceIds => _connectedDeviceIds;
  String? get connectedServerId => _connectedServerId;
  List<String> get receivedMessages => _receivedMessages;

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

  void addReceivedMessage(String message) {
    _receivedMessages.add(message);
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
