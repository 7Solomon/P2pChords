import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/groupManagement/Pages/allSongsPage.dart';
import 'package:P2pChords/customeWidgets/TileWidget.dart';
import 'package:provider/provider.dart';

class GroupSongsPage extends StatefulWidget {
  final String group;

  const GroupSongsPage({super.key, required this.group});

  @override
  _GroupSongsPageState createState() => _GroupSongsPageState();
}

class _GroupSongsPageState extends State<GroupSongsPage> {
  late final DataLoadeProvider _dataProvider;

  @override
  void initState() {
    super.initState();
    _dataProvider = Provider.of<DataLoadeProvider>(context, listen: false);
  }

  Future<void> _removeSongFromGroup(String jsonHash) async {
    await MultiJsonStorage.removeJsonFromGroup(widget.group, jsonHash);
    setState(() {
      _dataProvider.refreshData();
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
                        _dataProvider.refreshData();
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
            child: Consumer<DataLoadeProvider>(
              builder: (context, dataProvider, child) {
                if (dataProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Check if groups or songs are null
                if (dataProvider.groups == null || dataProvider.songs == null) {
                  return const Center(child: Text('Keine Daten verfügbar'));
                }

                // Get songs in the current group
                final List<Song> songs =
                    dataProvider.getSongsInGroup(widget.group);

                if (songs.isEmpty) {
                  return const Center(
                      child: Text('In dieser Gruppe sind keine Lieder'));
                }

                return ListView(
                  children: songs.map((entry) {
                    final songHeader = entry.header;
                    final songHash = entry.hash;
                    final songName = songHeader.name;

                    final songData = entry.sections;
                    if (songData.isEmpty) {
                      return Dismissible(
                          key: Key(songHash),
                          background: Container(color: Colors.red),
                          direction: DismissDirection.startToEnd,
                          confirmDismiss: (direction) async {
                            if (widget.group == 'default') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Lieder können nicht aus der Standardgruppe gelöscht werden.'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return false;
                            }
                            return true;
                          },
                          onDismissed: (direction) async {
                            await _removeSongFromGroup(songHash);
                          },
                          child: CustomListTile(
                            title: 'Unknown SongData Please Fix!',
                            subtitle: songHash,
                            arrowBool: false,
                            iconBool: false,
                          ));
                    }
                    return Dismissible(
                      key: Key(songHash),
                      background: Container(color: Colors.red),
                      direction: DismissDirection.startToEnd,
                      onDismissed: (direction) async {
                        await _removeSongFromGroup(songHash);
                      },
                      child: CustomListTile(
                        title: songName,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        subtitle: songHash,
                        arrowBool: false,
                        iconBool: false,
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
                Navigator.of(context).pop();
                // Call the method to delete the group
                MultiJsonStorage.removeGroup(widget.group).then((_) {
                  if (mounted) {
                    Navigator.of(context).pop(); // Close the screen
                    _dataProvider.refreshData();
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
