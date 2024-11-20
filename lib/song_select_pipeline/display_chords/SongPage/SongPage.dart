import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/SongDisplayScreen.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/displayFunctions.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/songsDrawerWidget.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/uiSettings.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/loadData.dart';
import 'package:provider/provider.dart';

class ChordSheetPage extends StatefulWidget {
  //final Map<String, dynamic> songsData;
  const ChordSheetPage({Key? key}) : super(key: key);
  @override
  _ChordSheetPageState createState() => _ChordSheetPageState();
}

class _ChordSheetPageState extends State<ChordSheetPage> {
  late UiSettings globalSongData;
  late NearbyMusicSyncProvider musicSyncProvider;

  bool isLoadingMapping = true;

  void displaySnack(String str) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(str)));
  }

  Future<void> _initializeData() async {
    try {
      final loadedMappings = await loadMappings(
          'assets/nashville_to_chord_by_key.json', displaySnack);
      if (loadedMappings != null && loadedMappings.isNotEmpty) {
        setState(() {
          globalSongData.setNashvileMappings(loadedMappings);
          isLoadingMapping = false;
        });
      } else {
        throw Exception("Mappings loaded but is empty or invalid");
      }
    } catch (e) {
      displaySnack("Error loading mappings: ${e.toString()}");
      // Handle additional error cases as needed
    }
  }

  // For Drawer

  @override
  void initState() {
    super.initState();
    globalSongData = Provider.of<UiSettings>(context, listen: false);
    musicSyncProvider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Songs"),
        ),
        drawer: Consumer<UiSettings>(
          builder: (context, globalData, child) {
            return SongDrawer(
              songData: globalData.songsDataMap[globalData.currentSongHash],
              currentKey: globalData.currentKey,
              onKeyChanged: (newKey) {
                setState(() {
                  globalData.setCurrentKey(newKey);
                  _initializeData();
                });
              },
            );
          },
        ),
        body: GestureDetector(
          onTapDown: (TapDownDetails details) {
            // Get screen height
            final screenHeight = MediaQuery.of(context).size.height;
            final screenWidth = MediaQuery.of(context).size.width;

            // Check if the tap occurred in the top half
            if (details.globalPosition.dy < screenHeight / 2 &&
                !(details.globalPosition.dx > screenWidth * 3 / 4)) {
              globalSongData.updateListOfDisplaySectionsUp();
              musicSyncProvider.sendUpdateToClients(
                  globalSongData.currentSongHash,
                  globalSongData.startIndexofSection);
            } else if (details.globalPosition.dy > screenHeight / 2 &&
                !(details.globalPosition.dx > screenWidth * 3 / 4)) {
              globalSongData.updateListOfDisplaySectionsDown();
              musicSyncProvider.sendUpdateToClients(
                  globalSongData.currentSongHash,
                  globalSongData.startIndexofSection);
            }
          },
          child: Consumer<UiSettings>(
            builder: (context, globalData, child) {
              return QuickSelectOverlay(
                items: globalData.songsDataMap,
                currentsong: globalData.currentSongHash,
                onItemSelected: (String songHash) {
                  setState(() {
                    globalData.setCurrentSong(songHash);
                    globalData.getListOfDisplaySections(0);
                  });
                },
                child: Row(
                  children: [
                    Expanded(
                      flex: 9,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: isLoadingMapping
                              ? const Center(child: CircularProgressIndicator())
                              : globalData.songsDataMap.isNotEmpty
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: displaySectionContent(
                                          globalData:
                                              globalData, // was widget.globalData.groupSongMap before, viellecicht so schöner
                                          uiDisplaySectionData:
                                              globalData.uiSectionData,
                                          key: globalData.currentKey,
                                          mappings:
                                              globalSongData.nashvileMappings,
                                          displaySnack: displaySnack),
                                    )
                                  : const Text("Keine Daten um anzuzeigen"),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ));
  }
}
