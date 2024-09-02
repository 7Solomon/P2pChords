import 'package:flutter/material.dart';
import 'package:P2pChords/data_management/save_json_in_storage.dart';
import 'package:P2pChords/display_groups/songGroupPage.dart';

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
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createNewGroup,
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
              return ListTile(
                title: Text(group),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupSongsPage(group: group),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
