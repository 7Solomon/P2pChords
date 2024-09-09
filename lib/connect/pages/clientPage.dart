import 'dart:typed_data';
import 'package:P2pChords/connect/connectionLogic/dataReceptionLogic.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:P2pChords/state.dart';
import 'package:P2pChords/device.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({Key? key}) : super(key: key);

  @override
  _ClientPageState createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final Strategy _strategy = Strategy.P2P_CLUSTER;
  final Map<String, DeviceInfo> _endpointMap = {};

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
        _displaySnack('Received Data');
        DataReceptionHandler(context).handlePayloadReceived(id, payload);
      },
    );
  }

  Future<void> _startDiscovery() async {
    final globalName = Provider.of<GlobalName>(context, listen: false);
    try {
      final success = await Nearby().startDiscovery(
        globalName.name,
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          setState(() {
            _endpointMap[id] = DeviceInfo(name, serviceId);
          });
        },
        onEndpointLost: (id) {
          setState(() {
            _endpointMap.remove(id);
          });
        },
      );
      _displaySnack("Discovery successful: $success");
    } catch (e) {
      _displaySnack("Error in discovery: $e");
    }
  }

  Future<void> _requestConnection(String id) async {
    final globalName = Provider.of<GlobalName>(context, listen: false);
    final globalUserIds = Provider.of<GlobalUserIds>(context, listen: false);
    try {
      final success = await Nearby().requestConnection(
        globalName.name,
        id,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            setState(() {
              globalUserIds.setConnectedServerId(id);
            });
          }
          _displaySnack(status.toString());
        },
        onDisconnected: (id) {
          setState(() {
            globalUserIds.setConnectedServerId('none');
            _endpointMap.remove(id);
          });
        },
      );
      _displaySnack("Requested connection successful: $success");
    } catch (e) {
      _displaySnack("Error in requesting connection: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalUserIds = Provider.of<GlobalUserIds>(context, listen: false);

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
              onPressed: _startDiscovery,
            ),
            const SizedBox(height: 24),
            Text(
              'Connected Device: ${globalUserIds.connectedServerId ?? "None"}',
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
                              onPressed: () => _requestConnection(id),
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
