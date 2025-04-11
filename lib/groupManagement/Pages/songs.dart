import 'package:P2pChords/dataManagment/converter/page.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider.dart';
import 'package:P2pChords/styling/Tiles.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/dataManagment/Pages/load_json_page.dart';
import 'package:provider/provider.dart';

//import 'package:P2pChords/customeWidgets/TileWidget.dart';

class AllSongsPage extends StatefulWidget {
  final String group;
  final VoidCallback onSongAdded;

  const AllSongsPage(
      {super.key, required this.group, required this.onSongAdded});

  @override
  _AllSongsPageState createState() => _AllSongsPageState();
}

class _AllSongsPageState extends State<AllSongsPage> {
  late final DataLoadeProvider _dataProvider;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dataProvider = Provider.of<DataLoadeProvider>(context, listen: false);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Map<String, Song> _getFilteredSongs(Map<String, Song> allSongs) {
    if (_searchQuery.isEmpty) {
      return allSongs;
    }

    return Map.fromEntries(allSongs.entries.where((entry) {
      final song = entry.value;
      // Search in song name
      final nameMatch = song.header.name.toLowerCase().contains(_searchQuery);
      // Search in authors if available
      final authorMatch = song.header.authors.isNotEmpty
          ? song.header.authors
              .any((author) => author.toLowerCase().contains(_searchQuery))
          : false;
      // Search in key
      final keyMatch = song.header.key.toLowerCase().contains(_searchQuery);

      return nameMatch || authorMatch || keyMatch;
    }));
  }

  void _loadData() {
    if (_dataProvider.songs == null || _dataProvider.groups == null) {
      _dataProvider.refreshData();
    }
  }

  Future<void> _addSongToGroup(String key) async {
    Song? song = await MultiJsonStorage.loadJson(key);
    if (song != null) {
      await MultiJsonStorage.saveJson(
        song,
        group: widget.group,
      );

      // Muss vielleich noch anders gelöst werden
      _dataProvider.refreshData();
      widget.onSongAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alle Lieder'),
      ),
      body: Column(
        children: [
          //Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suche nach Titel oder Künstler...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          //List of all songs
          Expanded(
            child: Consumer<DataLoadeProvider>(
              builder: (context, dataProvider, child) {
                if (dataProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (dataProvider.songs.isEmpty) {
                  return const Center(child: Text('Keine Lieder Verfügbar'));
                }

                // Get filtered songs based on search query
                final filteredSongs = _getFilteredSongs(dataProvider.songs);
                final groupSongs = dataProvider.groups[widget.group];

                if (filteredSongs.isEmpty) {
                  return const Center(
                    child: Text('Keine Ergebnisse gefunden'),
                  );
                }

                return ListView(
                  children: filteredSongs.entries.map((entry) {
                    final key = entry.key;
                    final songData = entry.value;
                    final isInGroup = groupSongs!.contains(key);
                    return CDissmissible.deleteAndAction(
                      key: Key(key),
                      deleteConfirmation: () =>
                          CDissmissible.showDeleteConfirmationDialog(context),
                      confirmDeleteDismiss: () async {
                        await MultiJsonStorage.removeJson(key);
                        dataProvider.refreshData();
                        return Future.value(true);
                      },
                      confirmActionDismiss: () async {
                        await _addSongToGroup(key);
                        return Future.value(false);
                      },
                      actionIcon: Icons.add,
                      child: Container(
                        color: isInGroup
                            ? Colors.blue.withOpacity(0.8)
                            : Colors.transparent,
                        child: ListTile(
                          title: Text(
                            songData.header.name,
                            style: TextStyle(
                              color: isInGroup ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            songData.header.authors.isNotEmpty
                                ? songData.header.authors.join(', ')
                                : '',
                            style: TextStyle(
                              color:
                                  isInGroup ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showOptionsMenu();
        },
        tooltip: 'Optionen',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Lied aus Datei importieren'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JsonFilePickerPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.create),
              title: const Text('Neues Lied erstellen'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConverterPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
