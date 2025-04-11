import 'package:P2pChords/dataManagment/Pages/edit/page.dart';
import 'package:P2pChords/dataManagment/Pages/file_picker.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider.dart';
import 'package:P2pChords/styling/SpeedDial.dart';
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

    await FilePickerUtil.pickAndEditSongFile(
      context,
      groupName: _groupSelector.text.isNotEmpty ? _groupSelector.text : null,
    );
    if (mounted) {
      Provider.of<DataLoadeProvider>(context, listen: false).refreshData();
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
