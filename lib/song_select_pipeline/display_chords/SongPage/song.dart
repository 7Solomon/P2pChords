import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/_components/song_selection.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawer.dart';
import 'package:P2pChords/state.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<CurrentSelectionProvider, DataLoadeProvider,
        SheetUiProvider, ConnectionProvider>(
      builder: (context, currentSelection, dataLoader, sheetUiProvider,
          connectionProvider, _) {
        if (currentSelection.currentGroup == null) {
          return const Scaffold(
            body: Center(
              child: Text('Keine Gruppe ausgewählt'),
            ),
          );
        }

        final List<Song> songs =
            dataLoader.getSongsInGroup(currentSelection.currentGroup!);
        final int songIndex = dataLoader.getSongIndex(
            currentSelection.currentGroup!, currentSelection.currentSongHash!);

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
                  currentKey: sheetUiProvider.currentKey ?? 'C',
                  onKeyChanged: (newKey) {
                    sheetUiProvider.setCurrentKey(newKey);
                  },
                ),
          //body: QuickSelectOverlay(
          //  key: _quickSelectKey,
          //  songs: dataLoader.getSongsInGroup(currentSelection.currentGroup!),
          //  currentsong: currentSelection.currentSongHash!,
          //  onItemSelected: (songHash) {
          //    // Handle song selection
          //  },
          body: SongSheetDisplay(
            songs: songs,
            songIndex: songIndex,
            sectionIndex: currentSelection.currentSectionIndex!,
            currentKey: sheetUiProvider.currentKey ?? 'C',
            startFontSize: sheetUiProvider.fontSize ?? 16.0,
            startSectionCount: sheetUiProvider.sectionCount ?? 2,
            onSectionChanged: (index) {
              currentSelection.setCurrentSectionIndex(index);
              if (connectionProvider.userState == UserState.server) {
                connectionProvider.dataSyncService
                    .sendUpdateToAllClients(currentSelection.toJson());
              }
            },
            onSongChanged: (index) {
              String hash = dataLoader.getHashByIndex(
                  currentSelection.currentGroup!, index);
              currentSelection.setCurrentSong(hash);
              if (connectionProvider.userState == UserState.server) {
                connectionProvider.dataSyncService
                    .sendUpdateToAllClients(currentSelection.toJson());
              }
            },
          ),
        );
      },
    );
  }
}
