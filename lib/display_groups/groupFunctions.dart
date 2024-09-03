import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:P2pChords/data_management/save_json_in_storage.dart';
import 'package:file_picker/file_picker.dart';

Future<void> importGroup() async {
  // Pick a file
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'], // Only allow JSON files
  );

  if (result != null && result.files.single.path != null) {
    String filePath = result.files.single.path!;
    String fileContent = await File(filePath).readAsString();

    Map<String, dynamic> jsonData = jsonDecode(fileContent);

    if (jsonData.containsKey('header') &&
        jsonData['header'].containsKey('group_name')) {
      // Assuming the JSON contains a group name and its songs
      String groupName = jsonData['group_name'] ?? 'Imported Group';
      Map<String, dynamic> songs = jsonData['songs'] ?? {};

      // Save the songs into the storage under the group name
      for (String songName in songs.keys) {
        await MultiJsonStorage.saveJson(songName, songs[songName],
            group: groupName);
      }
    }
  }
}

Future<void> exportGroup(String group_name, BuildContext context) async {
  // Load the group data
  Map<String, Map<String, dynamic>> jsons =
      await MultiJsonStorage.loadJsonsFromGroup(group_name);

  // Initialize the group JSON with a header
  Map<String, dynamic> groupJson = {
    'header': {'group_name': group_name, 'anzahl': jsons.length},
    'data': {} // Initialize 'data' as an empty map
  };

  try {
    Directory? downloadsDirectory = await getDownloadsDirectory();
    String filePath =
        '${downloadsDirectory!.path}/${group_name}_p2pController.json';

    // Convert the Map to a JSON string
    String jsonString = jsonEncode(groupJson);

    // Write the JSON string to the file
    File file = File(filePath);
    await file.writeAsString(jsonString);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('File saved to $filePath')));
    // return ('File saved to $filePath');
  } catch (e) {
    //return ('Error saving file: $e');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
  }
}

Future<void> showDeleteConfirmationDialog(
    BuildContext context, String group, VoidCallback onDeleteConfirmed) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Bestätige das Löschen'),
        content: const Text(
            'Bist du sicher, dass du die Gruppe permanent löschen willst? Das kann nicht mehr rückgängig gemacht werden.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              onDeleteConfirmed(); // Call the deletion callback
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Löschen'),
          ),
        ],
      );
    },
  );
}
