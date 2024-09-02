import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/data_management/save_json_in_storage.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/lyricsChordsClass.dart';

class ChordSheetPage extends StatefulWidget {
  final String songHash;

  // Constructor to accept song name and group
  ChordSheetPage({required this.songHash});
  @override
  _ChordSheetPageState createState() => _ChordSheetPageState();
}

class _ChordSheetPageState extends State<ChordSheetPage> {
  Map<String, dynamic>? songData;
  List<Widget> songStructure = [];
  Map<String, Map<String, String>> nashvilleToChordMapping = {};
  bool isLoadingSongData = true;
  bool isLoadingMapping = true;

  int _current_section_1 = 0;
  int _current_section_2 = 1;

  String currentKey = "C";

  void displaySnack(String str) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(str)));
  }

  Future<void> _initializeData() async {
    await loadMappings(); // Wait for mappings to be loaded
    await loadSongData(); // Then load song data
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> loadSongData() async {
    setState(() {
      isLoadingSongData = true;
    });

    try {
      Map<String, dynamic>? loadedSongData =
          await MultiJsonStorage.loadJson(widget.songHash);

      if (loadedSongData == null) {
        displaySnack('No data found for the provided hash.');
        return;
      }
      setState(() {
        songData = loadedSongData;
        if (songData != null) {
          songStructure = buildSongContent(songData!['data']);
        }
      });
    } catch (e) {
      displaySnack('An error occurred while loading song data: $e');
    } finally {
      setState(() {
        isLoadingSongData = false;
      });
    }
  }

  Future<void> loadMappings() async {
    setState(() {
      isLoadingMapping = true;
    });
    try {
      // Load Nashville to chord mapping
      String jsonString =
          await rootBundle.loadString('assets/nashville_to_chord_by_key.json');
      final dynamic decodedJson = json.decode(jsonString);
      setState(() {
        nashvilleToChordMapping = (decodedJson as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            key,
            (value as Map<String, dynamic>).map(
              (subKey, subValue) => MapEntry(subKey, subValue as String),
            ),
          ),
        );
      });
    } catch (e) {
      displaySnack(e.toString());
    } finally {
      setState(() {
        isLoadingMapping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingSongData || songData == null || isLoadingMapping) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(songData!['header']['name']),
      ),
      drawer: songData != null
          ? SongDrawer(
              songData: songData!,
              currentKey: currentKey,
              onKeyChanged: (newKey) {
                setState(() {
                  currentKey = newKey;
                  loadSongData(); // Rebuild song structure based on the new key
                });
              },
            )
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: displaySectionContent(),
          ),
        ),
      ),
    );
  }

  List<Widget> displaySectionContent() {
    List<Widget> displayData = [];
    if (_current_section_1 >= 0 && _current_section_1 < songStructure.length) {
      displayData.add(GestureDetector(
        onTap: () {
          setState(() {
            if (_current_section_1 > 0) {
              _current_section_2 = _current_section_1;
              _current_section_1--;
            }
          });
        },
        child: songStructure[_current_section_1],
      ));
    }
    if (_current_section_2 >= 0 && _current_section_2 < songStructure.length) {
      displayData.add(GestureDetector(
        onTap: () {
          setState(() {
            if (_current_section_2 < songStructure.length - 1) {
              _current_section_1 = _current_section_2;
              _current_section_2++;
            }
          });
        },
        child: songStructure[_current_section_2],
      ));
    }

    if (displayData.isEmpty) {
      return [const Text('Something went wrong')];
    }
    return displayData;
  }

  List<Widget> buildSongContent(Map<String, dynamic> data) {
    List<Widget> sectionWidgets = [];

    data.forEach((section, content) {
      List<Widget> oneSection = [];
      // Verse/chorus ansage
      oneSection.add(Text(
        section.toUpperCase(),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ));

      oneSection.add(const SizedBox(height: 10));

      // Richtiges Format?
      if (content is List<dynamic>) {
        for (var lineData in content) {
          if (lineData is Map<String, dynamic>) {
            oneSection.add(LyricsWithChords(
              lyrics: lineData['lyrics'] ?? '',
              chords: parseChords(lineData['chords']),
            ));
          } else {
            displaySnack('Unexpected line data format: $lineData');
          }
        }
      } else {
        displaySnack(
            'Unexpected content format for section $section: $content');
      }
      oneSection.add(const SizedBox(height: 20));

      sectionWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: oneSection,
        ),
      );
    });
    return sectionWidgets;
  }

  Map<String, String> parseChords(dynamic chordsData) {
    Map<String, String> parsedChords = {};
    if (chordsData is Map<String, dynamic>) {
      if (!nashvilleToChordMapping.containsKey(currentKey)) {
        displaySnack('Unknown key: $currentKey');
        return parsedChords;
      }
      Map<String, String> keyMapping = nashvilleToChordMapping[currentKey]!;
      chordsData.forEach((key, value) {
        int? position = int.tryParse(key);
        if (position != null && value is String) {
          String? chord = keyMapping[value];
          if (chord != null) {
            parsedChords[position.toString()] = chord;
          } else {
            displaySnack('Unknown Nashville number: $value');
          }
        } else {
          displaySnack('Invalid chord data: key=$key, value=$value');
        }
      });
    } else {
      displaySnack('Unexpected chords data format: $chordsData');
    }
    return parsedChords;
  }
}
