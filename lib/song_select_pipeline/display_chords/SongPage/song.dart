import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/_components/quick_select_overlay/overlay.dart'
    as quick_overlay;
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/_components/quick_select_overlay/overlay.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late QSelectOverlay _controller;

  void displaySnack(String str) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(str)));
    });
  }

  @override
  void initState() {
    super.initState();

    final CurrentSelectionProvider currentSelectionProvider =
        Provider.of<CurrentSelectionProvider>(context, listen: false);
    final DataLoadeProvider dataLoaderProvider =
        Provider.of<DataLoadeProvider>(context, listen: false);

    final List<String> songHashList =
        dataLoaderProvider.groups![currentSelectionProvider.currentGroup!];

    _controller = QSelectOverlay(
      songs: songHashList,
      initialSong: currentSelectionProvider.currentSongHash!,
      onSongSelected: (selectedSongHash) {
        setState(() {
          currentSelectionProvider.setCurrentSong(selectedSongHash);
        });
      },
    );
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
          key: _scaffoldKey,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              )
            ],
          ),
          endDrawer: SongDrawer(
            song: dataLoader.getSongByHash(currentSelection.currentSongHash!),
            currentKey: sheetUiProvider.currentKey,
            onKeyChanged: (newKey) {
              sheetUiProvider.setCurrentKey(newKey);
            },
          ),
          // Quick select overlay
          body: _controller.buildCHandler(
            context: context,
            child: Container(
              color: Colors.transparent,
              // This main Sheet
              child: SongSheetDisplay(
                songs: songs,
                songIndex: songIndex,
                sectionIndex: currentSelection.currentSectionIndex!,
                currentKey: sheetUiProvider.currentKey,
                uiVariables: sheetUiProvider.uiVariables,
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
            ),
          ),
        );
      },
    );
  }
}
