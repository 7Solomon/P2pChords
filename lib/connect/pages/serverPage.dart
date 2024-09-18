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
    final provider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    //provider.displaySnack() = _displaySnack;
    provider.checkPermissions();
  }

  void _displaySnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
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
              onPressed: () {
                songSyncProvider.startAdvertising();
              },
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
