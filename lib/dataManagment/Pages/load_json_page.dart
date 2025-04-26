import 'package:P2pChords/dataManagment/Pages/edit/page.dart';
import 'package:P2pChords/dataManagment/Pages/file_picker.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/styling/SpeedDial.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

class JsonFilePickerPage extends StatefulWidget {
  const JsonFilePickerPage({super.key});

  @override
  _JsonFilePickerPageState createState() => _JsonFilePickerPageState();
}

class _JsonFilePickerPageState extends State<JsonFilePickerPage> {
  bool _isLoading = false;
  final TextEditingController _groupSelector = TextEditingController();

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);

    Song? song = await FilePickerUtil.pickSongFile(
      context,
    );

    if (song != null && mounted) {
      // Navigate to a new instance of the editor with the loaded song
      Navigator.pushReplacement(
        // Use pushReplacement to replace the current editor
        context,
        MaterialPageRoute(
          builder: (context) => SongEditPage(
            song: song,
            group: _groupSelector.text.isNotEmpty ? _groupSelector.text : null,
          ),
        ),
      );
    } else if (song == null) {
      // Handle case where no file was picked or parsing failed
      SnackService()
          .showInfo('Keine Datei geladen oder es ist ein Fehler aufgetreten.');
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song laden'),
      ),
      floatingActionButton: CSpeedDial(
        theme: Theme.of(context),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.group_add),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Einen neuen Song Erstellen',
            onTap: () => (Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SongEditPage(
                  song: Song.empty(),
                ),
              ),
            )),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickFile,
              icon: const Icon(Icons.file_open),
              label: const Text('JSON-Datei auswählen und bearbeiten'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
