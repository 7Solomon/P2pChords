import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/songsDrawerWidget.dart';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/songPageFunctions.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/loadData.dart';
import 'package:provider/provider.dart';

class ChordSheetPage extends StatefulWidget {
  const ChordSheetPage();

  @override
  _ChordSheetPageState createState() => _ChordSheetPageState();
}

class _ChordSheetPageState extends State<ChordSheetPage> {
  Map<String, Map<String, dynamic>>? songDatas;
  Map<String, List<Widget>> songStructures = {}; // Corrected type
  Map<String, Map<String, String>> nashvilleToChordMapping = {};
  bool isLoadingSongData = true;
  bool isLoadingMapping = true;
  String currentKey = "C";
  Map<String, dynamic>? allGroups;

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

    // Load all groups
    allGroups = await MultiJsonStorage.getAllGroups();

    final currentSongData = Provider.of<SongProvider>(context, listen: false);
    // Load song data
    final songDataResult = await loadSongData(
      currentSongData,
      displaySnack,
      buildSongContent,
      parseChords,
      nashvilleToChordMapping,
      currentKey,
    );

    if (songDataResult != null) {
      setState(() {
        songDatas = songDataResult['songDatas'];
        songStructures = songDataResult['songStructures'];
        isLoadingSongData = false;
      });
    }
  }

  void onSongStart() async {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final List<Map<String, String>> allSongs =
        allGroups?[songProvider.currentGroup];

    if (allSongs.isNotEmpty) {
      for (int i = 1; i < allSongs.length; i++) {
        if (allSongs[i]['hash'] == songProvider.currentSongHash) {
          songProvider.updateSongHash(allSongs[i - 1]['hash']!);
          break; // Exit the loop once the song hash is updated
        }
      }
      return null; // Return null if no match or last element
    }
  }

  void onSongEnd() async {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final List<Map<String, String>> allSongs =
        allGroups?[songProvider.currentGroup];

    if (allSongs.isNotEmpty) {
      for (int i = 0; i < allSongs.length - 1; i++) {
        if (allSongs[i]['hash'] == songProvider.currentSongHash) {
          songProvider.updateSongHash(allSongs[i + 1]['hash']!);
          break; // Exit the loop once the song hash is updated
        }
      }
      return null; // Return null if no match or last element
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
        title: Consumer<SongProvider>(
          builder: (context, songProvider, child) {
            if (songProvider.currentSongHash != null) {
              _initializeData();
            }
            return Text(songDatas != null &&
                    songDatas![songProvider.currentSongHash] != null
                ? songDatas![songProvider.currentSongHash]!['header']['name']
                : 'Loading...');
          },
        ),
      ),
      drawer: Consumer<SongProvider>(
        builder: (context, songProvider, child) {
          if (songDatas != null &&
              songDatas![songProvider.currentSongHash] != null) {
            return SongDrawer(
              songData: songDatas![songProvider.currentSongHash]!,
              currentKey: currentKey,
              onKeyChanged: (newKey) {
                setState(() {
                  currentKey = newKey;
                  _initializeData();
                });
              },
            );
          } else {
            return Container();
          }
        },
      ),
      endDrawer: SongListDrawer(),
      body: Row(
        children: [
          Expanded(
            flex: 9,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Consumer<SongProvider>(
                  builder: (context, songProvider, child) {
                    //print(allGroups);
                    final List<Map<String, String>>? currentGroup =
                        allGroups?[songProvider.currentGroup];
                    final String? currentSongHash =
                        songProvider.currentSongHash;

                    // Ensure currentGroup is not null and has valid data
                    if (currentGroup != null &&
                        currentGroup.isNotEmpty &&
                        currentSongHash != null) {
                      // Proceed with displaying the content as you originally planned
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: displaySectionContent(
                          songStructure: songStructures,
                          groupSongs: currentGroup,
                          currentSongHash: currentSongHash,
                          currentSection1: songProvider.currentSection1,
                          currentSection2: songProvider.currentSection2,
                          updateSections: (section1, section2) {
                            songProvider.updateSections(section1, section2);
                          },
                          onEndReached: onSongEnd,
                          onStartReachedd: onSongStart,
                        ),
                      );
                    } else {
                      // Handle the case where data is null or invalid
                      return Text("No song data available.");
                    }
                  },
                ),
              ),
            ),
          ),
          Builder(
            builder: (context) => Container(
              width: 40,
              child: InkWell(
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: Container(
                  color: Colors.grey[300],
                  child: Container(
                    color: Colors.transparent,
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
