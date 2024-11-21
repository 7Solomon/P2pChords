import 'package:P2pChords/dataManagment/Pages/editJsonPage.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/groupManagement/songGroupPage.dart';
import 'package:P2pChords/groupManagement/groupFunctions.dart'; // Import your group functions here
import 'package:P2pChords/customeWidgets/TileWidget.dart';

class ManageGroupPage extends StatefulWidget {
  const ManageGroupPage({super.key});

  @override
  _ManageGroupPageState createState() => _ManageGroupPageState();
}

class _ManageGroupPageState extends State<ManageGroupPage> {
  Future<Map<String, List<Map<String, String>>>> _fetchGroups() async {
    final test = await MultiJsonStorage.getAllGroups();
    print(test);
    return await test;
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
                  //await MultiJsonStorage.saveJson(
                  //  newGroup,
                  //  {},          /// Das hier ist ganz quatschig, weil es keine Songs in der neuen gruppe gibt
                  //  group: newGroup,
                  //);

                  MultiJsonStorage.saveNewGroup(newGroup);
                  setState(() {});
                }
                Navigator.of(context).pop();
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
      body: FutureBuilder<Map<String, List<Map<String, String>>>>(
        future: _fetchGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Keine Gruppen vorhanden'));
          }

          final groups = snapshot.data!;
          return ListView(
            children: groups.keys.map((group) {
              return Dismissible(
                key: Key(group),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.blue,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.download, color: Colors.white),
                ),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await exportGroup(group, context);
                    return false; // Don't remove the item from the list
                  } else if (direction == DismissDirection.startToEnd) {
                    bool? deleteConfirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Bestätige das Löschen'),
                          content: const Text(
                              'Bist du sicher, dass du die Gruppe permanent löschen willst? Das kann nicht mehr rückgängig gemacht werden.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false); // Cancel
                              },
                              child: const Text('Abbrechen'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true); // Confirm
                              },
                              child: const Text('Löschen'),
                            ),
                          ],
                        );
                      },
                    );
                    if (deleteConfirmed == true) {
                      await MultiJsonStorage.removeGroup(group);
                      setState(() {});
                      return true; // Remove the item from the list
                    } else {
                      return false; // Don't remove the item
                    }
                  }
                  return false;
                },
                child: CustomListTile(
                  title: group,
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
                  onLongPress: () => {
                    //Navigator.push(
                    //  context,
                    //  MaterialPageRoute(
                    //    builder: (context) => JsonEditPage(jsonData: ,),
                    //  ),
                    //)
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
