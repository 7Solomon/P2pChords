import 'package:P2pChords/dataManagment/converter/page.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider.dart';
import 'package:P2pChords/styling/Tiles.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/dataManagment/Pages/saveJsonPage.dart';
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
  @override
  void initState() {
    super.initState();
    _dataProvider = Provider.of<DataLoadeProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
      body: Consumer<DataLoadeProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dataProvider.songs == null || dataProvider.songs!.isEmpty) {
            return const Center(child: Text('Keine Lieder Verfügbar'));
          }

          final songs = dataProvider.songs!;
          final groupSongs = dataProvider.groups?[widget.group] ?? [];

          return ListView(
            children: songs.entries.map((entry) {
              final key = entry.key;
              final songData = entry.value;
              final isInGroup = groupSongs.contains(key);
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
                    builder: (context) => JsonFilePickerPage(onSongAdded: () {
                      Provider.of<DataLoadeProvider>(context, listen: false)
                          .refreshData();
                    }),
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
