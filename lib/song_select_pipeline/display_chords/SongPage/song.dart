import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider/current_selection_provider.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/dataManagment/provider/sheet_ui_provider.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/_components/quick_select_overlay/overlay.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/sheet.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawer.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/utils/notification_service.dart';
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
        // Get Current Data
        final List<Song> songs =
            dataLoader.getSongsInGroup(currentSelection.currentGroup!);
        final int songIndex = dataLoader.getSongIndex(
            currentSelection.currentGroup!, currentSelection.currentSongHash!);
        final Song? currentSong =
            dataLoader.getSongByHash(currentSelection.currentSongHash!);

        // Initialize Quick Select Overlay
        final List<String> songHashList =
            dataLoader.groups[currentSelection.currentGroup!]!;
        _controller = QSelectOverlay(
          songs: songHashList,
          initialSong: currentSelection.currentSongHash!,
          onSongSelected: (selectedSongHash) {
            setState(() {
              currentSelection.setCurrentSong(selectedSongHash);
            });
          },
        );
        // return Empty check
        if (songs.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('Keine Lieder in der Gruppe'),
            ),
          );
        }

        if (songIndex == -1 || currentSong == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SnackService()
                .showError('Song Index ist -1 oder currentSong is null');
          });

          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
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
            song: currentSong,
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
                onSectionChanged: (index) {
                  currentSelection.setCurrentSectionIndex(index);
                  if (connectionProvider.userState == UserState.server) {
                    connectionProvider.dataSyncService
                        .sendUpdateToAllClients(currentSelection.toJson());
                  }
                },
                onSongChanged: (index) {
                  String? hash = dataLoader.getHashByIndex(
                      currentSelection.currentGroup!, index);

                  if (hash == null) {
                    SnackService().showError('Song nicht gefunden');
                    return;
                  }
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
