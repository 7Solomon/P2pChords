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

    final songSyncProvider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    // Load song data
    final songDataResult = await loadSongData(
      songSyncProvider,
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
    final songProvider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    final List<Map<String, String>> allSongs =
        allGroups?[songProvider.currentGroup];

    if (allSongs.isNotEmpty) {
      for (int i = 1; i < allSongs.length; i++) {
        if (allSongs[i]['hash'] == songProvider.currentSongHash) {
          songProvider.updateSongAndSection(allSongs[i - 1]['hash']!, 1, 2);
          break; // Exit the loop once the song hash is updated
        }
      }
      return null; // Return null if no match or last element
    }
  }

  void onSongEnd() async {
    final songSyncProvider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    final List<Map<String, String>> allSongs =
        allGroups?[songSyncProvider.currentGroup];

    if (allSongs.isNotEmpty) {
      for (int i = 0; i < allSongs.length - 1; i++) {
        if (allSongs[i]['hash'] == songSyncProvider.currentSongHash) {
          songSyncProvider.updateSongAndSection(allSongs[i + 1]['hash']!, 0, 1);
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
        title: Consumer<NearbyMusicSyncProvider>(
          builder: (context, songSyncProvider, child) {
            _initializeData();
            //print(songDatas![songSyncProvider.currentSongHash]);
            return Text(songDatas != null &&
                    songDatas![songSyncProvider.currentSongHash] != null
                ? songDatas![songSyncProvider.currentSongHash]!['header']
                    ['name']
                : 'Loading...');
          },
        ),
      ),
      drawer: Consumer<NearbyMusicSyncProvider>(
        builder: (context, songSyncProvider, child) {
          if (songDatas != null &&
              songDatas![songSyncProvider.currentSongHash] != null) {
            return SongDrawer(
              songData: songDatas![songSyncProvider.currentSongHash]!,
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
                child: Consumer<NearbyMusicSyncProvider>(
                  builder: (context, songSyncProvider, child) {
                    //print(allGroups);
                    final List<Map<String, String>>? currentGroup =
                        allGroups?[songSyncProvider.currentGroup];
                    final String currentSongHash =
                        songSyncProvider.currentSongHash;
                    // Ensure currentGroup is not null and has valid data
                    if (currentGroup != null && currentGroup.isNotEmpty) {
                      // Proceed with displaying the content as you originally planned
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: displaySectionContent(
                          songStructure: songStructures,
                          groupSongs: currentGroup,
                          currentSongHash: currentSongHash,
                          currentSection1: songSyncProvider.currentSection1,
                          currentSection2: songSyncProvider.currentSection2,
                          updateSections: (section1, section2) {
                            songSyncProvider.updateSongAndSection(
                                currentSongHash, section1, section2);
                          },
                          onEndReached: onSongStart,
                          onStartReachedd: onSongEnd,
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
