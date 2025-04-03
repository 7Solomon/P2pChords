import 'package:P2pChords/dataManagment/Pages/edit/page.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/groupManagement/Pages/group.dart';
import 'package:P2pChords/groupManagement/functions.dart'; // Import your group functions here
import 'package:P2pChords/styling/Tiles.dart';
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (String choice) {
              if (choice == 'Neue Gruppe') {
                _createNewGroup();
              } else if (choice == 'Gruppe importieren') {
                importGroup();
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Neue Gruppe', 'Gruppe importieren'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<DataLoadeProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = dataProvider.groups;
          if (groups == null || groups.isEmpty) {
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
