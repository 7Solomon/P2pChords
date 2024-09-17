import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:nearby_connections/nearby_connections.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({Key? key}) : super(key: key);

  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
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
    final provider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String message = String.fromCharCodes(payload.bytes!);
          provider.handleIncomingMessage(message);
        }
      },
    );
  }

  Future<void> _startAdvertising() async {
    final globalName = Provider.of<GlobalName>(context, listen: false);
    final provider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);

    provider.setAsServerDevice(true);
    final success =
        await provider.startAdvertising(globalName.name, _onConnectionInit);
    _displaySnack("Advertising ${success ? 'successful' : 'failed'}");
  }

  Future<void> _sendGroupData() async {
    final provider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    final songSyncProvider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);

    final groupSongData = await MultiJsonStorage.loadJsonsFromGroup(
        songSyncProvider.currentGroup);
    final success = await provider.sendGroupData(
        songSyncProvider.currentGroup, groupSongData);

    _displaySnack("Group data send ${success ? 'successful' : 'failed'}");
  }

  @override
  Widget build(BuildContext context) {
    final songSyncProvider = Provider.of<NearbyMusicSyncProvider>(context);
    final Set<String> connectedDeviceIds = songSyncProvider.connectedDeviceIds;

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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send Group Data',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: _sendGroupData,
            ),
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
