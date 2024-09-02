import 'package:flutter/material.dart';
import 'package:P2pChords/data_management/save_json_in_storage.dart';
import 'package:P2pChords/data_management/saveJsonPage.dart';

class AllSongsPage extends StatefulWidget {
  final String group;
  final VoidCallback onSongAdded;

  AllSongsPage({required this.group, required this.onSongAdded});

  @override
  _AllSongsPageState createState() => _AllSongsPageState();
}

class _AllSongsPageState extends State<AllSongsPage> {
  late Future<Map<String, dynamic>> _allSongsFuture;
  late Future<List<String>> _groupSongKeysFuture;

  @override
  void initState() {
    super.initState();
    _allSongsFuture = _fetchAllSongs();
    _groupSongKeysFuture = _fetchGroupSongKeys();
  }

  Future<Map<String, dynamic>> _fetchAllSongs() async {
    final groups = await MultiJsonStorage.getAllGroups();
    final allSongs = <String, dynamic>{};
    for (var group in groups.keys) {
      final songs = await MultiJsonStorage.loadJsonsFromGroup(group);
      allSongs.addAll(songs);
    }
    return allSongs;
  }

  Future<List<String>> _fetchGroupSongKeys() async {
    return await MultiJsonStorage.getAllKeys(widget.group);
  }

  Future<void> _addSongToGroup(String key) async {
    Map<String, dynamic>? songData = await MultiJsonStorage.loadJson(key);
    if (songData != null) {
      await MultiJsonStorage.saveJson(
        songData['name'] ?? 'Unbekannt',
        songData,
        group: widget.group,
      );
      setState(() {
        _groupSongKeysFuture = _fetchGroupSongKeys(); // Refresh group song keys
      });
      widget.onSongAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alle Lieder'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _allSongsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Keine Lieder Verfügbar'));
          }

          final songs = snapshot.data!;
          return FutureBuilder<List<String>>(
            future: _groupSongKeysFuture,
            builder: (context, groupSnapshot) {
              if (groupSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (groupSnapshot.hasError) {
                return Center(child: Text('Error: ${groupSnapshot.error}'));
              }

              final groupSongKeys = groupSnapshot.data ?? [];

              return ListView(
                children: songs.entries.map((entry) {
                  final key = entry.key;
                  final songData = entry.value;
                  final isInGroup = groupSongKeys.contains(key);

                  return Dismissible(
                    key: Key(key),
                    background: Container(color: Colors.blue),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await _addSongToGroup(key);
                    },
                    child: Container(
                      color: isInGroup
                          ? Colors.blue.withOpacity(0.8)
                          : Colors.transparent,
                      child: ListTile(
                        title: Text(
                          songData['header']['name'] ?? 'Unbekannt',
                          style: TextStyle(
                            color: isInGroup ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          key,
                          style: TextStyle(
                            color: isInGroup ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JsonFilePickerPage()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Song',
      ),
    );
  }
}
