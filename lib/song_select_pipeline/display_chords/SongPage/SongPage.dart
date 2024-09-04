import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/songPageFunctions.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/load_data.dart';
import 'package:provider/provider.dart';

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
      buildSongContent,
      parseChords,
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

  void _initProviders() {
    final globalMode = Provider.of<GlobalMode>(context, listen: false);
    final sectionProvider =
        Provider.of<SectionProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _initProviders();
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
          child: Consumer<SectionProvider>(
            builder: (context, sectionProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: displaySectionContent(
                  songStructure: songStructure,
                  currentSection1: sectionProvider.currentSection1,
                  currentSection2: sectionProvider.currentSection2,
                  updateSections: (section1, section2) {
                    sectionProvider.updateSections(section1, section2);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
