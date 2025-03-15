import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/dataManagment/dataClass.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  TestPageState createState() => TestPageState();
}

class TestPageState extends State<TestPage> {
  final DataLoadeProvider _dataLoader = DataLoadeProvider();
  bool _isLoading = true;
  String _debugOutput = "Loading data...";
  Map<String, dynamic>? _groups;
  Map<String, dynamic>? _songs;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Give the data loader time to load data
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _groups = _dataLoader.groups;
        _songs = _dataLoader.songs;
        _isLoading = false;
        _generateDebugOutput();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugOutput = "Error loading data: $e";
      });
    }
  }

  void _generateDebugOutput() {
    StringBuffer buffer = StringBuffer();

    // Groups debug info
    buffer.writeln("GROUPS DATA:");
    if (_groups == null) {
      buffer.writeln("  No groups data available");
    } else {
      buffer.writeln("  Found ${_groups!.length} groups");
      _groups!.forEach((groupName, songHashes) {
        buffer.writeln("  - Group: $groupName");
        buffer.writeln("    Songs: ${songHashes.length}");
        buffer.writeln("    Hashes: $songHashes");
      });
    }

    buffer.writeln("\n");

    // Songs debug info
    buffer.writeln("SONGS DATA:");
    if (_songs == null) {
      buffer.writeln("  No songs data available");
    } else {
      buffer.writeln("  Found ${_songs!.length} songs");
      _songs!.forEach((hash, song) {
        if (song is Song) {
          buffer.writeln("  - Song: ${song.header.name}");
          buffer.writeln("    Hash: ${song.hash}");
          buffer.writeln("    Key: ${song.header.key}");
          buffer.writeln("    Authors: ${song.header.authors.join(', ')}");
          buffer.writeln("    Sections: ${song.sections.length}");

          for (int i = 0; i < song.sections.length; i++) {
            SongSection section = song.sections[i];
            buffer.writeln("      Section $i: ${section.title}");
            buffer.writeln("      Lines: ${section.lines.length}");
          }
        } else {
          buffer.writeln("  - Song: $hash (Not a valid Song object: $song)");
        }
      });
    }

    _debugOutput = buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("P2pChords Debug Test"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _isLoading = true;
                _debugOutput = "Refreshing data...";
              });
              await _dataLoader.refreshData();
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Data Loader Debug Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _debugOutput,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Colors.lightGreenAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _loadData();
                    },
                    child: const Text("Reload Data"),
                  ),
                ],
              ),
            ),
    );
  }
}
