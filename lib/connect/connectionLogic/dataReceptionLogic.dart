/*import 'dart:convert';
import 'package:P2pChords/connect/connectionLogic/dataSendLogic.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:provider/provider.dart';

class DataReceptionHandler {
  final BuildContext context;
  late DataLoader test;

  DataReceptionHandler(this.context);
  void _displaySnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(
            seconds: 3), // Duration for the SnackBar to stay visible
        backgroundColor:
            Colors.blueAccent, // Optional: Customize the background color
        behavior: SnackBarBehavior
            .floating, // Optional: Make the SnackBar float above the content
      ),
    );
  }

  void handlePayloadReceived(String endpointId, Payload payload) async {
    final sectionMode = Provider.of<SongProvider>(context, listen: false);
    if (payload.type == PayloadType.BYTES) {
      String jsonString = String.fromCharCodes(payload.bytes!);
      Map<String, dynamic> data = json.decode(jsonString);

      if (data['type'] == 'groupData') {
        showDataReceivedDialog(data['content']);
        return;
      }
      if (data['type'] == 'songAnfrage') {
        Map songMap =
            await MultiJsonStorage.loadJsonsFromGroup(sectionMode.currentGroup);
        sendData(endpointId, {
          'type': 'groupData',
          'content': {'group': sectionMode.currentGroup, 'songs': songMap},
        });
        return;
      }
      if (data['type'] == 'songData') {
        print('NOt implemented');
        return;
      }
      if (data['type'] == 'songWechsel') {
        sectionMode.updateSongHash(data['content']);
        return;
      }
      if (data['type'] == 'sectionWeschel') {
        sectionMode.updateSections(
            data['content']['section1'], data['content']['section2']);
        return;
      }
      _displaySnack('Did receive sth but parsed Wrong');
      return;
    }
  }

  void showDataReceivedDialog(Map<String, dynamic> content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DataReceivedDialog(content: content);
      },
    );
  }
}

class DataReceivedDialog extends StatelessWidget {
  final Map<String, dynamic> content;

  DataReceivedDialog({required this.content});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Group Data Received'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Group Name: ${content['group']}'),
            Text('Number of Songs: ${content['songs'].length}'),
            Text('Do you want to accept this group data?'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Decline'),
          onPressed: () {
            Navigator.of(context).pop('decline');
          },
        ),
        TextButton(
          child: Text('Accept'),
          onPressed: () {
            Navigator.of(context).pop('accept');
          },
        ),
      ],
    );
  }
}
*/