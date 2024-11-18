import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/groupManagement/allSongsPage.dart';
import 'package:P2pChords/customeWidgets/TileWidget.dart';

class GroupSongsPage extends StatefulWidget {
  final String group;

  const GroupSongsPage({super.key, required this.group});

  @override
  _GroupSongsPageState createState() => _GroupSongsPageState();
}

class _GroupSongsPageState extends State<GroupSongsPage> {
  Future<Map<String, dynamic>> _fetchSongs() async {
    return await MultiJsonStorage.loadJsonsFromGroup(widget.group);
  }

  Future<void> _removeSongFromGroup(String jsonHash) async {
    await MultiJsonStorage.removeJsonFromGroup(widget.group, jsonHash);
    setState(() {
      _fetchSongs();
    }); // Refresh the UI after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllSongsPage(
                    group: widget.group,
                    onSongAdded: () {
                      setState(() {
                        _fetchSongs(); // Refresh the songs in GroupSongsPage
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _fetchSongs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('In dieser Gruppe sind keine Lieder'));
                }

                final songs = snapshot.data!;

                print(songs);
                if (songs.isNotEmpty) {
                  return ListView(
                    children: songs.entries.map((entry) {
                      final key = entry.key;
                      final Map songData = entry.value;
                      if (songData.isEmpty) {
                        return Dismissible(
                            key: Key(key),
                            background: Container(color: Colors.red),
                            direction: DismissDirection.startToEnd,
                            onDismissed: (direction) async {
                              await _removeSongFromGroup(key);
                            },
                            child: CustomListTile(
                              title: 'Unknown SongData Please Fix!',
                              subtitle: key,
                              arrowBool: false,
                              iconBool: false,
                            ));
                      }
                      return Dismissible(
                        key: Key(key),
                        background: Container(color: Colors.red),
                        direction: DismissDirection.startToEnd,
                        onDismissed: (direction) async {
                          await _removeSongFromGroup(key);
                        },
                        child: CustomListTile(
                          title: songData['header']['name'] ?? 'Unbekannt',
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          subtitle: key,
                          arrowBool: false,
                          iconBool: false,
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  return const Center(child: Text('Keine Lieder Verfügbar'));
                }
              },
            ),
          ),
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
                          'Bist du sicher das du die Gruppe Permanent Löschen willst, das kann nicht mehr rückgängig gemacht werden.'),
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
                            MultiJsonStorage.removeGroup(widget.group)
                                .then((_) {
                              Navigator.of(context).pop(); // Close the dialog
                              Navigator.of(context).pop(); // Close the screen
                              _fetchSongs();
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
