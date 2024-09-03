import 'package:flutter/material.dart';

import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/songPageFunctions.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/load_data.dart';

class ChordSheetPage extends StatefulWidget {
  final String songHash;

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
    // Load mappings
    final mappings = await loadMappings(
      'assets/nashville_to_chord_by_key.json',
      displaySnack,
    );
    if (mappings != null) {
      setState(() {
        nashvilleToChordMapping = mappings;
        isLoadingMapping = false;
      });
    }

    // Load song data
    final songDataResult = await loadSongData(
      widget.songHash,
      displaySnack,
      (data, displaySnack, parseChords) => buildSongContent(
        data,
        displaySnack,
        parseChords,
      ),
      (chordsData) => parseChords(
        chordsData,
        nashvilleToChordMapping,
        currentKey,
        displaySnack,
      ),
      nashvilleToChordMapping,
      currentKey,
    );

    if (songDataResult != null) {
      setState(() {
        songData = songDataResult['songData'];
        songStructure = songDataResult['songStructure'];
        isLoadingSongData = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
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
                  _initializeData(); // Reload data on key change
                });
              },
            )
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: displaySectionContent(
              songStructure: songStructure,
              currentSection1: _current_section_1,
              currentSection2: _current_section_2,
              updateSections: (section1, section2) {
                setState(() {
                  _current_section_1 = section1;
                  _current_section_2 = section2;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
