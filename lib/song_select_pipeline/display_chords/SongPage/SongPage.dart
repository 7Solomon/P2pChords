import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/SongDisplayScreen.dart';
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
      endDrawer: SongListDrawer(),
      body: Row(
        children: [
          Expanded(
            flex: 9,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Consumer<UiSettings>(
                  builder: (context, globalData, child) {
                    if (isLoadingMapping) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (globalData.songsDataMap.isNotEmpty) {
                      return SongDisplayScreen(
                          globalData: globalData,
                          mappings: globalData.nashvileMappings,
                          displaySnack: displaySnack,
                          openDrawer: () {
                            Scaffold.of(context).openEndDrawer();
                          });
                    } else {
                      // Handle the case where data is null or invalid
                      return const Text("Keine Daten um anzuzeigen");
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
