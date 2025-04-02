import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/key_selection.dart'; // Adjust the import as per your file structure

class SongDrawer extends StatelessWidget {
  final Song song;
  final String currentKey;
  final ValueChanged<String> onKeyChanged;

  const SongDrawer({
    super.key,
    required this.song,
    required this.currentKey,
    required this.onKeyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              song.header.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          // Song Data
          ListTile(
            title: Text(
              'Tonart: ${song.header.key}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: Text(
              'BPM: ${song.header.bpm}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: Text('Rhythmus: ${song.header.timeSignature}'),
          ),
          ListTile(
            title: Text('Autoren: ${song.header.authors.join(', ')}'),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Einstellungen'),
            onTap: () async {
              Navigator.pop(context); // Close the drawer
              final selectedKey = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => KeySelectionPage()),
              );
              if (selectedKey != null && selectedKey != currentKey) {
                onKeyChanged(
                    selectedKey); // Notify parent widget about the key change
              }
            },
          ),
        ],
      ),
    );
  }
}
