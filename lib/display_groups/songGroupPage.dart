import 'package:flutter/material.dart';
import 'package:P2pChords/data_management/save_json_in_storage.dart';
import 'package:P2pChords/display_groups/allSongsPage.dart';

class GroupSongsPage extends StatefulWidget {
  final String group;

  GroupSongsPage({required this.group});

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
            icon: Icon(Icons.list),
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
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('In dieser Gruppe sind keine Lieder'));
                }

                final songs = snapshot.data!;
                return ListView(
                  children: songs.entries.map((entry) {
                    final key = entry.key;
                    final songData = entry.value;
                    return Dismissible(
                      key: Key(key),
                      background: Container(color: Colors.red),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) async {
                        await _removeSongFromGroup(key);
                      },
                      child: ListTile(
                        title: Text(songData['header']['name'] ?? 'Unbekannt'),
                        subtitle: Text(key),
                      ),
                    );
                  }).toList(),
                );
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
