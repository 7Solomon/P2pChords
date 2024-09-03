import 'package:flutter/material.dart';
import 'package:P2pChords/data_management/save_json_in_storage.dart';
import 'package:P2pChords/display_groups/songGroupPage.dart';
import 'package:P2pChords/display_groups/groupFunctions.dart'; // Import your group functions here

class ManageGroupPage extends StatefulWidget {
  @override
  _ManageGroupPageState createState() => _ManageGroupPageState();
}

class _ManageGroupPageState extends State<ManageGroupPage> {
  Future<Map<String, List<Map<String, String>>>> _fetchGroups() async {
    return await MultiJsonStorage.getAllGroups();
  }

  Future<void> _createNewGroup() async {
    final TextEditingController _controller = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erstelle eine neue Gruppe'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Gruppen Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Erstellen'),
              onPressed: () async {
                String newGroup = _controller.text.trim();
                if (newGroup.isNotEmpty) {
                  await MultiJsonStorage.saveJson(
                    newGroup,
                    {},
                    group: newGroup,
                  );
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
        title: Text('Gruppen Übersicht'),
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
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<Map<String, String>>>>(
        future: _fetchGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Keine Gruppen vorhanden'));
          }

          final groups = snapshot.data!;
          return ListView(
            children: groups.keys.map((group) {
              return Dismissible(
                key: Key(group),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.blue,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.download, color: Colors.white),
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
                child: ListTile(
                  title: Text(group),
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
