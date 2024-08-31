import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/connect_pages/choose_sc_page.dart';
import 'dart:convert';

import 'send_data_page.dart';
import 'receive_data_page.dart';
import '../device.dart';
import '../state.dart';

class ConnectionPage extends StatefulWidget {
  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  Map<String, DeviceInfo> endpointMap = {};
  String? connectedDeviceId;
  final List<String> _receivedMessages = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      displaySnack("All permissions granted");
    } else {
      displaySnack("Some permissions were denied");
      // You might want to show a dialog here explaining why the permissions are needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('P2P Connection')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer2<GlobalMode, GlobalUserIds>(
            builder: (context, globalMode, globalUserIds, child) {
              switch (globalMode.userState) {
                case UserState.client:
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        child: const Text('Suche Server'),
                        onPressed: () => startDiscovery(),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          child: const Text('Empfange Datein'),
                          onPressed: () {
                            context
                                .read<GlobalMode>()
                                .setUserState(UserState.client);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ReceivingPage()),
                            );
                          }),
                      const SizedBox(height: 16),
                      Text(
                          'Connected Device: ${globalUserIds.connectedServerId}'),
                      const SizedBox(height: 16),
                      const Text('Available Servers:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // List of possible servers
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: endpointMap.length,
                        itemBuilder: (context, index) {
                          String id = endpointMap.keys.elementAt(index);
                          DeviceInfo deviceInfo = endpointMap[id]!;
                          return ListTile(
                            title: Text(deviceInfo.endpointName),
                            subtitle: Text(deviceInfo.serviceId),
                            onTap: () => requestConnection(id),
                          );
                        },
                      ),
                    ],
                  );

                // Server
                case UserState.server:
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        child: const Text('Starte Server'),
                        onPressed: () => startAdvertising(),
                      ),
                      ElevatedButton(
                        child: const Text('Sende Daten'),
                        onPressed: () {
                          context
                              .read<GlobalMode>()
                              .setUserState(UserState.server);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SendingPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('Connected Devices:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      if (globalUserIds.connectedDeviceIds.isEmpty)
                        const Text('No devices connected')
                      else
                        Column(
                          children:
                              globalUserIds.connectedDeviceIds.map((deviceId) {
                            return Text('Device: $deviceId');
                          }).toList(),
                        ),
                    ],
                  );

                // Nichts ausgewählt
                default:
                  return ElevatedButton(
                    child: const Text('Wähle Server oder Client'),
                    onPressed: () {
                      context.read<GlobalMode>().setUserState(UserState.client);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChooseSCStatePage()),
                      );
                    },
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  void startAdvertising() async {
    final globalName = Provider.of<GlobalName>(context, listen: false);
    final globalUserIds = Provider.of<GlobalUserIds>(context, listen: false);
    try {
      bool a = await Nearby().startAdvertising(
        globalName.name,
        strategy,
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {
          if (!mounted) return; // Check if widget is still mounted
          if (status == Status.CONNECTED) {
            globalUserIds.addConnectedDevice(id);
          }
          displaySnack(status.toString());
        },
        onDisconnected: (id) {
          if (!mounted) return; // Check if widget is still mounted
          globalUserIds.removeConnectedDevice(id);
          setState(() {
            endpointMap.remove(id);
          });
        },
      );
      if (mounted) {
        // Check if widget is still mounted
        displaySnack("Advertising successful: $a");
      }
    } catch (e) {
      if (mounted) {
        // Check if widget is still mounted
        displaySnack("Error in advertising: $e");
      }
    }
  }

  void startDiscovery() async {
    final globalName = Provider.of<GlobalName>(context, listen: false);
    try {
      bool a = await Nearby().startDiscovery(
        globalName.name,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          setState(() {
            endpointMap[id] = DeviceInfo(name, serviceId);
          });
        },
        onEndpointLost: (id) {
          setState(() {
            endpointMap.remove(id);
          });
        },
      );
      displaySnack("Discovery successful: $a");
    } catch (e) {
      displaySnack("Error in discovery: $e");
    }
  }

  void requestConnection(String id) async {
    final globalName = Provider.of<GlobalName>(context, listen: false);
    final globalUserId = Provider.of<GlobalUserIds>(context, listen: false);
    try {
      bool a = await Nearby().requestConnection(
        globalName.name,
        id,
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            setState(() {
              globalUserId.addConnectedDevice(id);
            });
          }
          displaySnack(status.toString());
        },
        onDisconnected: (id) {
          setState(() {
            globalUserId.removeConnectedDevice(id);
            endpointMap.remove(id);
          });
        },
      );
      displaySnack("Requested connection successful: $a");
    } catch (e) {
      displaySnack("Error in requesting connection: $e");
    }
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    final globalUserIds = Provider.of<GlobalUserIds>(context, listen: false);
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String str = String.fromCharCodes(payload.bytes!);
          globalUserIds.addReceivedMessage(str);
        }
      },
    );
  }

  void displaySnack(String str) {
    if (!mounted) return; // Check if widget is still mounted
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(str)));
  }
}
