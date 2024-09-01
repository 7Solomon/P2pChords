import 'dart:convert';

import 'package:flutter/material.dart';
import 'save_json_in_storage.dart';
import 'package:P2pChords/display_chords/SongPage.dart';

class Songoverviewpage extends StatelessWidget {
  final String groupName;
  final List<String> songs;

  Songoverviewpage({required this.groupName, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Songs in $groupName'),
      ),
      body: Column(
        children: [
          // Expanded widget allows the ListView to take up remaining space
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final songName = songs[index];

                return Dismissible(
                  key: Key(songName), // Unique key for each item
                  direction:
                      DismissDirection.endToStart, // Swipe from right to left
                  background: Container(
                    color: Colors.red,
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Bestätige Löschen'),
                          content: const Text(
                              'Bist du sicher das du diesen Song permanent Löschen willst?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(
                                    false); // Return false to cancel deletion
                              },
                              child: const Text('Abbrechen'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(
                                    true); // Return true to confirm deletion
                              },
                              child: const Text('Löschen'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    // Handle the deletion logic here
                    MultiJsonStorage.removeJson(songName, group: groupName)
                        .then((success) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$songName Gelöscht')),
                        );
                      }
                    });
                  },
                  child: ListTile(
                    title: Text(songName),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChordSheetPage(
                            songName: songName,
                            group: groupName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Löschen der Gruppe
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              child: const Text('Lösche Gruppe'),
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Bestätige das Löschen'),
                      content: const Text(
                          'Bist du sicher das du die Gruppe Permanent Löschen willst, das kann nicht mehr rückgängig gemacht werde.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Call the method to delete the group
                            MultiJsonStorage.removeGroup(groupName).then((_) {
                              Navigator.of(context).pop(); // Close the dialog
                              Navigator.of(context)
                                  .pop(); // Close the screen or go back to the previous screen
                            });
                          },
                          child: const Text('Löschen'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
