import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/displayFunctions.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/songsDrawerWidget.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/uiSettings.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/loadData.dart';
import 'package:provider/provider.dart';

class ChordSheetPage extends StatefulWidget {
  const ChordSheetPage({Key? key}) : super(key: key);

  @override
  _ChordSheetPageState createState() => _ChordSheetPageState();
}

class _ChordSheetPageState extends State<ChordSheetPage> {
  late bool isLoadingMapping;
  late final globalSongData;
  late final songSyncProvider;

  void displaySnack(String str) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(str)));
    });
  }

  Future<void> _initializeData(UiSettings globalSongData) async {
    try {
      final loadedMappings = await loadMappings(
        'assets/nashville_to_chord_by_key.json',
        displaySnack,
      );

      if (loadedMappings != null && loadedMappings.isNotEmpty) {
        globalSongData.setNashvileMappings(loadedMappings);
        setState(() {
          isLoadingMapping = false;
        });
      } else {
        throw Exception("Mappings loaded but is empty or invalid");
      }
    } catch (e) {
      displaySnack("Error loading mappings: ${e.toString()}");
    }
  }

  bool _isLoading = false;
  Map<String, Map<String, Map>> _allGroupData = {};
  Map<String, List<Map<String, String>>> _allGroups = {};
  Future<void> _loadAllJsons() async {
    //print('Loading all JSONs');

    setState(() => _isLoading = true);
    _allGroups = await MultiJsonStorage.getAllGroups();

    for (MapEntry<String, List<Map<String, String>>> entry
        in _allGroups.entries) {
      String groupName = entry.key;
      List<Map<String, String>> groupValue = entry.value;
      _allGroupData[groupName] = {};

      // Initialize the songs list for each group
      for (Map<String, String> songValue in groupValue) {
        String songHash = songValue['hash']!;

        Map<String, dynamic>? songData =
            await MultiJsonStorage.loadJson(songHash);
        if (songData != null) {
          _allGroupData[groupName]![songHash] = songData;
        }
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    // Move initialization to post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globalSongData = Provider.of<UiSettings>(context, listen: false);
      if (globalSongData.nashvileMappings.isEmpty) {
        _initializeData(globalSongData);
      } else {
        setState(() {
          isLoadingMapping = false;
        });
      }
    });
  }

  void _handleTapDown(TapDownDetails details, BuildContext context,
      UiSettings globalData, NearbyMusicSyncProvider musicSyncProvider) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = details.globalPosition.dx <= screenWidth * 3 / 4;

    if (isLeftSide) {
      if (details.globalPosition.dy < screenHeight / 2) {
        globalData.updateListOfDisplaySectionsUp();
      } else {
        globalData.updateListOfDisplaySectionsDown();
      }

      if (musicSyncProvider.userState == UserState.server) {
        musicSyncProvider.sendUpdateToClients(
          globalData.currentSongHash,
          globalData.startIndexofSection,
          globalData.currentGroup,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UiSettings, NearbyMusicSyncProvider>(
      builder: (context, globalData, musicSyncProvider, _) {
        if (globalData.songsDataMap.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _loadAllJsons();

            if (globalData.currentGroup != "") {
              print('globalData.currentGroup not ""');
              final Map<String, Map> songsDataMap =
                  _allGroupData[globalData.currentGroup] ?? {};

              globalData.setSongsDataMap(songsDataMap);
            } else {
              //songSyncProvider.askForGroup();
            }
          });
        } else {
          print('globalData.songsDataMap not empty');
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text("Songs"),
          ),
          drawer: globalData.songsDataMap[globalData.currentSongHash] == null
              ? const Drawer(
                  child: Text('Not Available'),
                )
              : SongDrawer(
                  songData: globalData.songsDataMap[globalData.currentSongHash],
                  currentKey: globalData.currentKey,
                  onKeyChanged: (newKey) {
                    globalData.setCurrentKey(newKey);
                    _initializeData(globalData);
                  },
                ),
          body: GestureDetector(
            onTapDown: (details) =>
                _handleTapDown(details, context, globalData, musicSyncProvider),
            child: QuickSelectOverlay(
              items: globalData.songsDataMap,
              currentsong: globalData.currentSongHash,
              onItemSelected: (String songHash) {
                globalData.setCurrentSong(songHash);
                globalData.getListOfDisplaySections(0);
                musicSyncProvider.sendUpdateToClients(
                    globalData.currentSongHash,
                    globalData.startIndexofSection,
                    globalData.currentGroup);
              },
              child: Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child:
                            isLoadingMapping //globalData.nashvileMappings.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : globalData.songsDataMap.isNotEmpty
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: displaySectionContent(
                                          globalData: globalData,
                                          uiDisplaySectionData:
                                              globalData.uiSectionData,
                                          key: globalData.currentKey,
                                          mappings: globalData.nashvileMappings,
                                          displaySnack: displaySnack,
                                        )
                                            .map((widget) =>
                                                Flexible(child: widget))
                                            .toList(),
                                      )
                                    : const Text("Keine Daten um anzuzeigen"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
