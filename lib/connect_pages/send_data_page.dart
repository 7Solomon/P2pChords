import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:provider/provider.dart';
import '../state.dart';

class SendingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final globalUserIds = Provider.of<GlobalUserIds>(context);

    void displaySnack(String str) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(str)));
    }

    void sendData(String data) async {
      final bytes = Uint8List.fromList(data.codeUnits);
      final connectedDeviceIds = globalUserIds.connectedDeviceIds;

      for (String deviceId in connectedDeviceIds) {
        try {
          await Nearby().sendBytesPayload(deviceId, bytes);
          displaySnack("Data sent successfully to $deviceId: $data");
        } catch (e) {
          displaySnack("Error sending data to $deviceId: $e");
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Send Data')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Send "1" to all clients'),
              onPressed: () => sendData("1"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Send "2" to all clients'),
              onPressed: () => sendData("2"),
            ),
          ],
        ),
      ),
    );
  }
}
