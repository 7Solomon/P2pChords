import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/songsDrawerWidget.dart';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/songPageFunctions.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/load_data.dart';
import 'package:provider/provider.dart';

class ChordSheetPage extends StatefulWidget {
  const ChordSheetPage();

  @override
  _ChordSheetPageState createState() => _ChordSheetPageState();
}

class _ChordSheetPageState extends State<ChordSheetPage> {
  Map<String, dynamic>? songData;
  List<Widget> songStructure = [];
  Map<String, Map<String, String>> nashvilleToChordMapping = {};
  bool isLoadingSongData = true;
  bool isLoadingMapping = true;

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

    final currentSongData = Provider.of<SongProvider>(context, listen: false);
    // Load song data
    final songDataResult = await loadSongData(
      currentSongData.currentSongHash,
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

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(songData != null ? songData!['header']['name'] : 'Loading...'),
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
      endDrawer: SongListDrawer(),
      body: Row(
        children: [
          Expanded(
            flex: 9,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Consumer<SongProvider>(
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
          ),
          Builder(
            builder: (context) => Container(
              width: 40, // Increased width for better touch target
              child: InkWell(
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: Container(
                  color: Colors.grey[300],
                  child: Container(
                    color: Colors.transparent, // Transparent background
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
