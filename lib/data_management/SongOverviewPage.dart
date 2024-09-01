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

                return ListTile(
                  title: Text(songName),
                  onTap: () {
                    // Handle song tap here, e.g., show song details
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
                );
              },
            ),
          ),
          // Button placed at the bottom of the screen
          //Padding(
          //  padding: const EdgeInsets.all(16.0),
          //  child: TextButton(
          //    child: const Text('Delete Group'),
          //    onPressed: () {
          //      // Assuming MultiJsonStorage is a service for managing your storage
          //      MultiJsonStorage.removeJson(groupName).then((_) {
          //        Navigator.of(context).pop();
          // _loadAllJsons would be a function to refresh your data after deletion
          //_loadAllJsons();
          //      });
          //    },
          //  ),
          //),
        ],
      ),
    );
  }
}
