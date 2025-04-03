import 'dart:convert';
import 'dart:typed_data';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/networking/nearby_service.dart';

class DataSyncService {
  // Singleton pattern
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;

  // Notification callback for important events
  late Function(String) onNotification;
  late Function(String, Uint8List) sendBytesPayload;
  late Set<String> connectedDeviceIds;

  DataSyncService._internal();

  void _notify(String message) {
    // DAS HIER GEHT NICHT!!!!
    // KA WHY
    onNotification(message);
  }

  // Send update data to a specific client
  Future<bool> sendUpdateToClient(
      String deviceId, Map<String, dynamic> updateData) async {
    Map<String, dynamic> data = {'type': 'update', 'content': updateData};
    return _sendDataToDevice(deviceId, data);
  }

  // Send song data to a specific client
  Future<bool> sendSongDataToClient(String deviceId, SongData songData) async {
    Map<String, dynamic> data = {
      'type': 'songData',
      'content': {
        'songData': songData.toMap(),
      }
    };
    return _sendDataToDevice(deviceId, data);
  }

  // Send update data to all connected clients
  Future<bool> sendUpdateToAllClients(Map<String, dynamic> updateData) async {
    Map<String, dynamic> data = {'type': 'update', 'content': updateData};
    return _sendDataToAllDevices(data);
  }

  // Send song data to all connected clients
  Future<bool> sendSongDataToAllClients(SongData songData) async {
    Map<String, dynamic> data = {
      'type': 'songData',
      'content': {
        'songData': songData.toMap(),
      }
    };
    return _sendDataToAllDevices(data);
  }

  // Helper method to send data to a specific device
  Future<bool> _sendDataToDevice(
      String deviceId, Map<String, dynamic> data) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(json.encode(data)));
      await sendBytesPayload(deviceId, bytes);
      _notify('Data sent successfully to device: $deviceId');
      return true;
    } catch (e) {
      _notify('Error sending data to device $deviceId: $e');
      return false;
    }
  }

  // Helper method to send data to all connected devices
  Future<bool> _sendDataToAllDevices(Map<String, dynamic> data) async {
    bool allSuccess = true;
    try {
      for (String id in connectedDeviceIds) {
        bool result = await _sendDataToDevice(id, data);
        if (!result) {
          allSuccess = false;
          _notify('Error sending data to device with id: $id');
        }
      }
      return allSuccess;
    } catch (e) {
      _notify('Error sending data to all devices: $e');
      return false;
    }
  }
}
