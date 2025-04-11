import 'dart:convert';
import 'dart:io';
import 'package:P2pChords/dataManagment/Pages/edit/page.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../storageManager.dart';

class JsonFilePickerPage extends StatefulWidget {
  final VoidCallback onSongAdded;
  const JsonFilePickerPage({super.key, required this.onSongAdded});

  @override
  _JsonFilePickerPageState createState() => _JsonFilePickerPageState();
}

class _JsonFilePickerPageState extends State<JsonFilePickerPage> {
  bool _isLoading = false;
  final TextEditingController _groupSelector = TextEditingController();

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();

        // Validate JSON and convert to Song
        Map<String, dynamic> jsonData = jsonDecode(content);
        Song loadedSong = Song.fromMap(jsonData);

        // Navigate to the edit page with the loaded song
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongEditPage(
                song: loadedSong,
                group:
                    _groupSelector.text.isNotEmpty ? _groupSelector.text : null,
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showSnackBar('Error loading file: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _groupSelector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song laden'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _groupSelector,
              decoration: const InputDecoration(
                labelText: 'Gruppe für diesen Song',
                hintText: 'In welche Gruppe soll der Song gespeichert werden?',
                border: OutlineInputBorder(),
              ),
            ),
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
