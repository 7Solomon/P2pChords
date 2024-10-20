import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/device.dart';
import 'package:nearby_connections/nearby_connections.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({Key? key}) : super(key: key);

  @override
  _ClientPageState createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final Map<String, DeviceInfo> _endpointMap = {};

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
    //_displaySnack("Permissions checked");
  }

  void _displaySnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final songSyncProvider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Connection'),
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
                'Search for Servers',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: () {
                songSyncProvider.startAdvertising();
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Connected Device: ${songSyncProvider.connectedDeviceIds}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Servers:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _endpointMap.isNotEmpty
                  ? ListView.builder(
                      itemCount: _endpointMap.length,
                      itemBuilder: (context, index) {
                        final id = _endpointMap.keys.elementAt(index);
                        final deviceInfo = _endpointMap[id]!;

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              deviceInfo.endpointName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              deviceInfo.serviceId,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.link),
                              onPressed: () =>
                                  songSyncProvider.requestConnection(id),
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text('No servers found.'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
