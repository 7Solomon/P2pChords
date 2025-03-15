import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/displayFunctions.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/songsDrawerWidget.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/UiSettings/page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChordSheetPage extends StatefulWidget {
  const ChordSheetPage({Key? key}) : super(key: key);

  @override
  _ChordSheetPageState createState() => _ChordSheetPageState();
}

class _ChordSheetPageState extends State<ChordSheetPage> {
  void displaySnack(String str) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(str)));
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChordUtils.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<CurrentSelectionProvider, DataLoadeProvider, UIProvider,
        NearbyMusicSyncProvider>(
      builder: (context, currentSelection, dataLoader, uiProvider,
          musicSyncProvider, _) {
        if (currentSelection.currentGroup == null) {
          return const Scaffold(
            body: Center(
              child: Text('Keine Gruppe ausgewählt'),
            ),
          );
        }

        final List<Song> songs =
            dataLoader.getSongsInGroup(currentSelection.currentGroup!);
        if (songs.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('Keine Lieder in der Gruppe'),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text("Songs"),
          ),
          drawer: songs.isEmpty
              ? const Drawer(
                  child: Text('Keine Songs in der Gruppe'),
                )
              : SongDrawer(
                  song: dataLoader
                      .getSongByHash(currentSelection.currentSongHash!),
                  currentKey: uiProvider.currentKey ?? 'C',
                  onKeyChanged: (newKey) {
                    uiProvider.setCurrentKey(newKey);
                  },
                ),
          body: SongSheetDisplay(
            song: dataLoader.getSongByHash(currentSelection.currentSongHash!),
            currentKey: uiProvider.currentKey ?? 'C',
            startFontSize: uiProvider.fontSize ?? 16.0,
            onSectionChanged: (index) {
              // Update current section index
              currentSelection.setCurrentSongIndex(index);

              // If this is a server, notify clients
              if (musicSyncProvider.userState == UserState.server) {
                musicSyncProvider
                    .sendUpdateToClients(currentSelection.toJson());
              }
            },
          ),
        );
      },
    );
  }
}
