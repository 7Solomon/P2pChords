import 'package:P2pChords/dataManagment/Pages/edit/page.dart';
import 'package:P2pChords/dataManagment/Pages/load_json_page.dart';
import 'package:P2pChords/dataManagment/data_base/page.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider.dart';
import 'package:P2pChords/styling/SpeedDial.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/groupManagement/Pages/group.dart';
import 'package:P2pChords/groupManagement/functions.dart';
import 'package:P2pChords/styling/Tiles.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

class ManageGroupPage extends StatefulWidget {
  const ManageGroupPage({super.key});

  @override
  _ManageGroupPageState createState() => _ManageGroupPageState();
}

class _ManageGroupPageState extends State<ManageGroupPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataLoadeProvider>(context, listen: false).refreshData();
    });
  }

  Future<void> _createNewGroup() async {
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
                  await MultiJsonStorage.saveNewGroup(newGroup);
                  final dataProvider =
                      Provider.of<DataLoadeProvider>(context, listen: false);
                  await dataProvider.refreshData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gruppe "$newGroup" erstellt'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gruppen Übersicht'),
      ),
      floatingActionButton: HierarchicalSpeedDial(
        theme: Theme.of(context),
        categories: [
          SpeedDialCategory(
            title: 'Gruppen',
            icon: Icons.add_circle,
            color: Colors.blue,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.group_add),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                label: 'Neue Gruppe',
                onTap: () => _createNewGroup(),
              ),
              SpeedDialChild(
                child: const Icon(Icons.download),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                label: 'Gruppe importieren',
                onTap: () => importGroup(),
              ),
            ],
          ),
          SpeedDialCategory(
            title: 'Songs',
            icon: Icons.add_circle,
            color: Colors.orange,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.add),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                label: 'Song erstellen',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SongEditPage(
                        song: Song.empty(),
                      ),
                    ),
                  );
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.download),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                label: 'Song Importieren',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JsonFilePickerPage(),
                    ),
                  );
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.download),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                label: 'Songs aus einem Server importieren',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServerImportPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: Consumer<DataLoadeProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = dataProvider.groups;
          if (groups.isEmpty) {
            return const Center(child: Text('Keine Gruppen vorhanden'));
          }
          return ListView(
            children: groups.keys.map((group) {
              return CDissmissible.deleteAndAction(
                key: Key(group),
                deleteIcon: Icons.delete,
                actionIcon: Icons.download,
                deleteConfirmation: () =>
                    CDissmissible.showDeleteConfirmationDialog(context),
                confirmActionDismiss: () async {
                  SongData songsdata = dataProvider.getSongData(group);
                  await exportGroupsData(songsdata);
                },
                confirmDeleteDismiss: () async {
                  await MultiJsonStorage.removeGroup(group);
                  dataProvider.refreshData();
                  setState(() {});
                },
                child: CListTile(
                  title: group,
                  context: context,
                  icon: Icons.file_copy,
                  subtitle: 'Klicke um die Songs der Gruppe anzusehen',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupSongsPage(group: group),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
