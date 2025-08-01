import 'dart:convert';
import 'dart:io';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/networking/auth.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

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

    SongData songData = SongData.fromMap(jsonData);

    for (var data in songData.groups.entries) {
      await MultiJsonStorage.saveNewGroup(data.key);
      for (String hash in data.value) {
        await MultiJsonStorage.saveJson(songData.songs[hash]!, group: data.key);
      }
    }
  }
}

Future<void> createNewGroupDialog(BuildContext context) async {
  final TextEditingController controller = TextEditingController();
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Erstelle eine neue Gruppe'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Gruppen Name'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Abbrechen'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Erstellen'),
            onPressed: () async {
              String newGroup = controller.text.trim();
              if (newGroup.isNotEmpty) {
                //await MultiJsonStorage.saveNewGroup(newGroup);
                Provider.of<DataLoadeProvider>(context, listen: false)
                    .addGroup(newGroup);

                SnackService().showSuccess(
                  'Gruppe "$newGroup" erstellt',
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}

Future<bool> exportGroupsData(SongData songsData) async {
  // In exportGroupsData function
  String groups = songsData.groups.keys.join('-');
  String groupHash =
      sha256.convert(utf8.encode(groups)).toString().substring(0, 8);
  try {
    Directory? downloadsDirectory = await getDownloadsDirectory();
    String filePath =
        '${downloadsDirectory!.path}/${groupHash}_p2pController.json';

    // Convert the Map to a JSON string
    String jsonString = jsonEncode(songsData.toMap());

    // Write the JSON string to the file
    File file = File(filePath);
    await file.writeAsString(jsonString);

    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> downloadSong(Song song) async {
  String songHash = song.hash;
  try {
    Directory? downloadsDirectory = await getDownloadsDirectory();
    String authorName;
    if (song.header.authors.isNotEmpty) {
      authorName = song.header.authors[0];
    } else {
      authorName = 'unknown';
    }
    String filePath =
        '${downloadsDirectory!.path}/${song.header.name}_$authorName.json';

    // Convert the Map to a JSON string
    String jsonString = jsonEncode(song.toMap());

    // Write the JSON string to the file
    File file = File(filePath);
    await file.writeAsString(jsonString);

    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> sendToServer(Song song) async {
  SnackService().showWarning(
    'Sende den Song "${song.header.name}" auf den Server... ABER IST NICHT IMPLEMENTeRIT DU KEK',
  );
  return false;
  //final _tokenManager = ApiTokenManager();
  //String? token = await _tokenManager.getToken();
}

Future<void> exportSong(BuildContext context, Song song) async {
  // In exportGroupsData function
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exportiere den Song'),
          content: const Text('Was willst du mit dem Song machen?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Downloaden'),
              onPressed: () async {
                bool success = await downloadSong(song);
                if (success) {
                  SnackService().showSuccess(
                    'Song "${song.header.name}" exportiert!',
                  );
                } else {
                  SnackService().showError(
                    'Fehler beim Exportieren des Songs.',
                  );
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Auf einen Server senden'),
              onPressed: () async {
                bool success = await sendToServer(song);
                if (success) {
                  SnackService().showSuccess(
                    'Song "${song.header.name}" auf den Server gesendet!',
                  );
                } else {
                  SnackService().showError(
                    'Fehler beim Senden des Songs auf den Server.',
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
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
