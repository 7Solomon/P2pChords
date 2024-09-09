import 'package:P2pChords/connect/connectionLogic/dataReceptionLogic.dart';
import 'package:P2pChords/connect/connectionLogic/dataSendLogic.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({Key? key}) : super(key: key);

  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  final Strategy _strategy = Strategy.P2P_CLUSTER;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
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

  void _displaySnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _onConnectionInit(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        DataReceptionHandler(context).handlePayloadReceived(id, payload);
      },
    );
  }

  Future<void> _startAdvertising() async {
    final globalName = Provider.of<GlobalName>(context, listen: false);
    final globalUserIds = Provider.of<GlobalUserIds>(context, listen: false);
    try {
      final success = await Nearby().startAdvertising(
        globalName.name,
        _strategy,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            globalUserIds.addConnectedDevice(id);
          }
          _displaySnack(status.toString());
        },
        onDisconnected: (id) {
          globalUserIds.removeConnectedDevice(id);
          setState(() {
            // Handle disconnection
          });
        },
      );
      _displaySnack("Advertising successful: $success");
    } catch (e) {
      _displaySnack("Error in advertising: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalUserIds = Provider.of<GlobalUserIds>(context);
    final currentSongData = Provider.of<SongProvider>(context);
    final Set<String> connectedDeviceIds = globalUserIds.connectedDeviceIds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Page'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Start Server',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: _startAdvertising,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: () async {
                  final groupSongData =
                      await MultiJsonStorage.loadJsonsFromGroup(
                          currentSongData.currentGroup);

                  final data = {
                    'type': 'groupData',
                    'content': {
                      'group': currentSongData.currentGroup,
                      'songs': groupSongData
                    },
                  };

                  sendDataToAllClients(data, globalUserIds.connectedDeviceIds);
                },
                child: Text('Send')),
            const SizedBox(height: 24),
            const Text(
              'Connected Devices:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: connectedDeviceIds.isNotEmpty
                  ? ListView(
                      children: connectedDeviceIds.map((deviceId) {
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              'Device ID: $deviceId',
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: const Icon(Icons.device_hub),
                          ),
                        );
                      }).toList(),
                    )
                  : const Center(
                      child: Text(
                        'No devices connected',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
