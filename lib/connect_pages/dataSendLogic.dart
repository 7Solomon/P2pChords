import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';

Future<Map> sendDataToAllClients(
    Map<String, dynamic> data, Set<String> connectedDeviceIds) async {
  Map<String, bool> statusi = {};
  for (String deviceId in connectedDeviceIds) {
    bool status = await sendData(deviceId, data);
    statusi[deviceId] = status;
  }
  return statusi;
}

Future<bool> sendData(String deviceId, Map<String, dynamic> data) async {
  try {
    final codeUnits = json.encode(data).codeUnits;
    final bytes = Uint8List.fromList(codeUnits);
    await Nearby().sendBytesPayload(deviceId, bytes);
    print("Data sent successfully to $deviceId");
    return true;
  } catch (e) {
    print("Error sending data to $deviceId: $e");
    return false;
  }
}

Future<bool> sendRequest(String deviceId) async {
  Map data = {
    'type': 'songAnfrage',
  };

  // Create a Completer to handle the async response

  try {
    final codeUnits = json.encode(data).codeUnits;
    final bytes = Uint8List.fromList(codeUnits);
    await Nearby().sendBytesPayload(deviceId, bytes);

    // Wait for the response (the future will complete when the response is received)
    return true;
  } catch (e) {
    return false;
  }
}
