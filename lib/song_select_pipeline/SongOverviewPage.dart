import 'dart:convert';
import 'dart:math';

import 'package:P2pChords/dataManagment/Pages/editJsonPage.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/uiSettings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/SongPage.dart';

import 'package:P2pChords/customeWidgets/TileWidget.dart';

class Songoverviewpage extends StatelessWidget {
  final VoidCallback onGroupDeleted;

  const Songoverviewpage({super.key, required this.onGroupDeleted});

  @override
  Widget build(BuildContext context) {
    final songSyncProvider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    final uiSettings = context.watch<UiSettings>();
    //print(songSyncProvider.currentGroup);
    return Scaffold(
      appBar: AppBar(
        title: Text('Songs in ${songSyncProvider.currentGroup}'),
      ),
      body: Column(
        children: [
          FutureBuilder(
              future: MultiJsonStorage.loadJsonsFromGroup(
                  songSyncProvider.currentGroup),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No songs available'));
                }
                // Extract the data from snapshot
                final Map<String, Map<String, dynamic>> songsData =
                    snapshot.data!;
                //
                //print(songsData);

                //final List<String> songshashList = data[0] as List<String>;
                //final Map<String, List<Map<String, String>>> groups =
                //   data[1] as Map<String, List<Map<String, String>>>;
                //print("Songs: $songshashList");
                //print("Groups: $groups");

                return Expanded(
                  child: ListView.builder(
                    itemCount: songsData.length,
                    itemBuilder: (context, index) {
                      final hash = songsData.keys.elementAt(index);
                      final song = songsData[hash]!;
                      final name = song['header']['name'] ?? 'noName';

                      return

                          /*
                      Dismissible(
                        key: Key(hash), // Unique key for each item
                        direction: DismissDirection
                            .endToStart, // Swipe from right to left
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
                          MultiJsonStorage.removeJson(hash).then((success) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$name Gelöscht')),
                              );
                            }
                          });
                        },
                       

                        // Hier den Namen dann einfügen
                        child: */
                          CustomListTile(
                        title: name,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16.0),
                        iconBool: false,
                        onTap: () {
                          //print(songsData);
                          List<int> sectionIndexes = List.generate(
                              // Ist noch alles quatsch hier
                              min(songsData.length,
                                  uiSettings.secctionIndexSize),
                              (index) => index + 1);
                          songSyncProvider.updateSongAndSection(
                              hash, [0, 1], uiSettings.secctionIndexSize);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChordSheetPage(),
                            ),
                          );
                        },
                        onLongPress: () {
                          // Edit Json Data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JsonEditPage(
                                jsonData: song,
                                saveJson: (String json) {
                                  MultiJsonStorage.saveJson(
                                      hash, jsonDecode(json),
                                      group: songSyncProvider.currentGroup);
                                },
                              ),
                            ),
                          );
                        },
                        //),
                      );
                    },
                  ),
                );
              })
          /*
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
                              onGroupDeleted();
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
          ),*/
        ],
      ),
    );
  }
}
