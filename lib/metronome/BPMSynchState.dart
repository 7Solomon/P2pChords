import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

//class BpmSyncProvider with ChangeNotifier {
//  final Nearby _nearby = Nearby();
//  bool _isServerDevice = false;
//  double _bpm = 120.0;
//  Timer? _clickTimer;
//  DateTime? _lastSyncTime;
//
//  bool get isServerDevice => _isServerDevice;
//  double get bpm => _bpm;
//
//  void setAsServerDevice(bool isServer) {
//    _isServerDevice = isServer;
//    notifyListeners();
//  }
//
//  void updateBpm(double newBpm) {
//    if (_isServerDevice) {
//      _bpm = newBpm;
//      _sendBpmUpdate();
//      _restartClickTimer();
//      notifyListeners();
//    }
//  }
//
//  void _sendBpmUpdate() {
//    if (_isServerDevice) {
//      final message = {
//        'type': 'bpm_update',
//        'bpm': _bpm,
//        'timestamp': DateTime.now().millisecondsSinceEpoch
//      };
//      _sendToAllClients(message);
//    }
//  }
//
//  void _sendToAllClients(Map<String, dynamic> message) {
//    final bytes = Uint8List.fromList(message.toString().codeUnits);
//    _nearby.sendBytesPayload('*', bytes);
//  }
//
//  void handleIncomingMessage(Map<String, dynamic> message) {
//    if (message['type'] == 'bpm_update' && !_isServerDevice) {
//      _bpm = message['bpm'];
//      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
//      _restartClickTimer();
//      notifyListeners();
//    }
//  }
//
//  void _restartClickTimer() {
//    _clickTimer?.cancel();
//    final interval = (60 / _bpm) * 1000;
//    _clickTimer = Timer.periodic(Duration(milliseconds: interval.round()), (_) {
//      _onBeatTick();
//    });
//  }
//
//  void _onBeatTick() {
//    // Implement your click logic here
//    print('Beat');
//    // You can also notify listeners here if you want to update UI on each beat
//  }
//
//  // Call this method when cleaning up
//  void dispose() {
//    _clickTimer?.cancel();
//    super.dispose();
//  }
//}
