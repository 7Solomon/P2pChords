import 'dart:convert';
import 'package:P2pChords/connect_pages/dataSendLogic.dart';
import 'package:P2pChords/data_management/save_json_in_storage.dart';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:provider/provider.dart';

class DataReceptionHandler {
  final BuildContext context;

  DataReceptionHandler(this.context);

  void handlePayloadReceived(String endpointId, Payload payload) async {
    final sectionMode = Provider.of<SectionProvider>(context, listen: false);
    if (payload.type == PayloadType.BYTES) {
      String jsonString = String.fromCharCodes(payload.bytes!);
      Map<String, dynamic> data = json.decode(jsonString);

      if (data['type'] == 'groupData') {
        showDataReceivedDialog(data['content']);
      }
      if (data['type'] == 'songAnfrage') {
        Map songMap =
            await MultiJsonStorage.loadJsonsFromGroup(sectionMode.currentGroup);
        sendData(endpointId, {
          'type': 'groupData',
          'content': {'group': sectionMode.currentGroup, 'songs': songMap},
        });
      }
      if (data['type'] == 'songData') {
        print('NOt implemented');
      }
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
