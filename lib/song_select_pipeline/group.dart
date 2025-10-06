import 'package:P2pChords/dataManagment/Pages/edit/page.dart';
import 'package:P2pChords/dataManagment/provider/current_selection_provider.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/dataManagment/provider/sheet_ui_provider.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/groupManagement/floating_buttons.dart';
import 'package:P2pChords/groupManagement/functions.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/styling/SpeedDial.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/song.dart';

import 'package:P2pChords/styling/Tiles.dart';

class Songoverviewpage extends StatefulWidget {
  const Songoverviewpage({super.key});

  @override
  State<Songoverviewpage> createState() => _SongoverviewpageState();
}

class _SongoverviewpageState extends State<Songoverviewpage> {
  String? _expandedSongHash;

  @override
  Widget build(BuildContext context) {
    final currentData = context.watch<CurrentSelectionProvider>();
    final dataProvider = context.watch<DataLoadeProvider>();
    final musicSyncProvider = context.watch<ConnectionProvider>();
    final sheetUiProvider = context.watch<SheetUiProvider>();

    final songs = dataProvider.getSongsInGroup(currentData.currentGroup!);

    return Scaffold(
      appBar: AppBar(
        title: Text('Songs in ${currentData.currentGroup}'),
      ),
      floatingActionButton:
          buildFloatingActionButtonForGroup(context, currentData.currentGroup!),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              itemCount: songs.length,
              onReorder: (oldIndex, newIndex) async {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                await dataProvider.reorderSongInGroup(
                  currentData.currentGroup!,
                  oldIndex,
                  newIndex,
                );
              },
              itemBuilder: (context, index) {
                final song = songs[index];
                final name = song.header.name;
                final hash = song.hash;
                final isExpanded = _expandedSongHash == hash;

                // SET KEY MAP OF CURRENT SONG TO its ORIGINAL KEY
                if (!sheetUiProvider.currentKeyMap.containsKey(song.hash)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    sheetUiProvider.setCurrentSongKeyInMap(
                        song.hash, song.header.key);
                  });
                }

                return CExpandableListTile(
                  key: ValueKey(hash),
                  uniqueKey: hash,
                  title: name,
                  subtitle: song.header.authors.isNotEmpty
                      ? song.header.authors[0]
                      : '',
                  icon: Icons.music_note,
                  isExpanded: isExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedSongHash = expanded ? hash : null;
                    });
                  },
                  dragHandleBuilder: (context) {
                    return ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.drag_handle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    );
                  },
                  onTap: () {
                    if (isExpanded) {
                      setState(() {
                        _expandedSongHash = null;
                      });
                      return;
                    }

                    currentData.setCurrentSong(hash);
                    currentData.setCurrentSectionIndex(0);

                    musicSyncProvider.dataSyncService
                        .sendUpdateToAllClients(currentData.toJson());

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChordSheetPage(),
                      ),
                    );
                  },
                  actions: [
                    CExpandableAction(
                      icon: Icons.edit,
                      tooltip: 'Bearbeiten',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SongEditPage(
                              song: song,
                              group: currentData.currentGroup,
                            ),
                          ),
                        );
                      },
                    ),
                    CExpandableAction(
                      icon: Icons.share,
                      tooltip: 'Exportieren',
                      onPressed: () {
                        exportSong(context, song);
                      },
                    ),
                    CExpandableAction(
                      icon: Icons.delete,
                      tooltip: 'Löschen',
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      onPressed: () async {
                        final confirmed = await CDissmissible
                            .showDeleteConfirmationDialog(context);
                        if (confirmed == true) {
                          await dataProvider.removeSongFromGroup(
                            currentData.currentGroup!,
                            hash,
                          );
                          if (currentData.currentSongHash == hash) {
                            currentData.setCurrentSong(null);
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
