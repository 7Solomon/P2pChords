import 'dart:convert';
import 'dart:io';
import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../storageManager.dart';

class JsonFilePickerPage extends StatefulWidget {
  final VoidCallback onSongAdded;
  const JsonFilePickerPage({super.key, required this.onSongAdded});

  @override
  _JsonFilePickerPageState createState() => _JsonFilePickerPageState();
}

class _JsonFilePickerPageState extends State<JsonFilePickerPage> {
  File? _selectedFile;
  String? _fileName;
  String? _fileContent;
  bool _isLoading = false;
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  final TextEditingController _groupSelector = TextEditingController();

  void _showSnackBar(String message) {
    // Instead of using context, use the ScaffoldMessengerState directly
    _scaffoldKey.currentState?.showSnackBar(
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

        // Validate JSON
        jsonDecode(content);

        setState(() {
          _selectedFile = file;
          _fileName = path.basename(file.path);
          _fileContent = content;

          // Update overview
          widget.onSongAdded();
        });
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveJson() async {
    if (_selectedFile == null || _fileName == null || _fileContent == null) {
      _showSnackBar(
        'Please select a valid JSON file first',
      );
      return;
    }

    setState(() => _isLoading = true);
    Map<String, dynamic> jsonData = jsonDecode(_fileContent!);
    Song song = Song.fromMap(jsonData);

    String groupIndex =
        _groupSelector.text.isEmpty ? 'default' : _groupSelector.text;

    await MultiJsonStorage.saveJson(song, group: groupIndex);

    _showSnackBar('JSON file saved successfully');

    Navigator.of(context).pop();

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _groupSelector
        .dispose(); // Dispose of the controller when the widget is disposed
    //could be Irelevant becaus eit doesnt change sth
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick JSON File'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Wrap the Column in SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : _pickFile,
                child: const Text('Select JSON File'),
              ),
              const SizedBox(height: 16),
              if (_fileName != null)
                Text('Selected file: $_fileName',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              if (_fileContent != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_fileContent!),
                  ),
                ),
              ElevatedButton(
                onPressed: () {
                  print('Save JSON');
                  print(_isLoading);
                  print(_selectedFile);
                  _isLoading || _selectedFile == null ? null : _saveJson();
                },
                child: const Text('Save JSON'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
