import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:P2pChords/connect/connectionLogic/dataReceptionLogic.dart';
import 'package:P2pChords/main.dart';
import 'package:P2pChords/connect/pages/choosePage.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/SongPage.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';

import '../device.dart';
import '../state.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({Key? key}) : super(key: key);

  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
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
    //final sectionProvider = Provider.of<SongProvider>(context, listen: false);
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        DataReceptionHandler(context).handlePayloadReceived(id, payload);
      },
    );
  }

  Future<void> _handleReceivedSongData(Map<String, dynamic> songData,
      {String songGroup = 'default'}) async {
    final sectionProvider = Provider.of<SongProvider>(context, listen: false);

    final songName = songData['header']['name'];
    final songResult =
        await MultiJsonStorage.saveJson(songName, songData, group: songGroup);

    if (songResult['result']) {
      sectionProvider.updateSongHash(songResult['hash']);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChordSheetPage()),
      );
    }
  }

  Future<void> _sendPayload(
      String deviceId, Map<String, dynamic> data, String type) async {
    final payload = {'type': type, 'content': data};
    try {
      final bytes = Uint8List.fromList(jsonEncode(payload).codeUnits);
      await Nearby().sendBytesPayload(deviceId, bytes);
      _displaySnack("Data sent successfully to $deviceId: $payload");
    } catch (e) {
      _displaySnack("Error sending data to $deviceId: $e");
    }
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
            _endpointMap.remove(id);
          });
        },
      );
      if (mounted) {
        _displaySnack("Advertising successful: $success");
      }
    } catch (e) {
      if (mounted) {
        _displaySnack("Error in advertising: $e");
      }
    }
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
              globalUserIds.addConnectedDevice(id);
            });
          }
          _displaySnack(status.toString());
        },
        onDisconnected: (id) {
          setState(() {
            globalUserIds.removeConnectedDevice(id);
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
    return Scaffold(
      appBar: AppBar(title: const Text('P2P Connection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Consumer2<GlobalMode, GlobalUserIds>(
          builder: (context, globalMode, globalUserIds, child) {
            switch (globalMode.userState) {
              case UserState.client:
                return _buildClientView(globalUserIds);
              case UserState.server:
                return _buildServerView(globalUserIds);
              default:
                return _buildDefaultView();
            }
          },
        ),
      ),
    );
  }

  Widget _buildClientView(GlobalUserIds globalUserIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          child: const Text('Suche Server'),
          onPressed: _startDiscovery,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          child: const Text('Empfange Datein'),
          onPressed: () {
            context.read<GlobalMode>().setUserState(UserState.client);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Connected Device: ${globalUserIds.connectedServerId}'),
        const SizedBox(height: 16),
        const Text('Available Servers:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _endpointMap.length,
          itemBuilder: (context, index) {
            final id = _endpointMap.keys.elementAt(index);
            final deviceInfo = _endpointMap[id]!;
            return ListTile(
              title: Text(deviceInfo.endpointName),
              subtitle: Text(deviceInfo.serviceId),
              onTap: () => _requestConnection(id),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServerView(GlobalUserIds globalUserIds) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: const Text('Starte Server'),
          onPressed: _startAdvertising,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue[700],
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        SizedBox(height: 20),
        const Text('Connected Devices:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        if (globalUserIds.connectedDeviceIds.isEmpty)
          const Text('No devices connected')
        else
          ...globalUserIds.connectedDeviceIds
              .map((deviceId) => Text('Device: $deviceId')),
      ],
    );
  }

  Widget _buildDefaultView() {
    return ElevatedButton(
      child: const Text('Wähle Server oder Client'),
      onPressed: () {
        context.read<GlobalMode>().setUserState(UserState.client);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChooseSCStatePage()),
        );
      },
    );
  }
}
