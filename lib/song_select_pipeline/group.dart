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

class Songoverviewpage extends StatelessWidget {
  const Songoverviewpage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentData = context.watch<CurrentSelectionProvider>();
    final dataProvider = context.watch<DataLoadeProvider>();
    final musicSyncProvider = context.watch<ConnectionProvider>();
    final sheetUiProvider = context.watch<SheetUiProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Songs in ${currentData.currentGroup}'),
      ),
      floatingActionButton:
          buildFloatingActionButtonForGroup(context, currentData.currentGroup!),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: dataProvider
                  .getSongsInGroup(currentData.currentGroup!)
                  .length,
              itemBuilder: (context, index) {
                final song = dataProvider
                    .getSongsInGroup(currentData.currentGroup!)[index];
                final name = song.header.name;
                final hash = song.hash;

                // SET KEY MAP OF CURRENT SONG TO its ORIGINAL KEY
                if (!sheetUiProvider.currentKeyMap.containsKey(song.hash)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    sheetUiProvider.setCurrentSongKeyInMap(
                        song.hash, song.header.key);
                  });
                }

                return CDissmissible.deleteAndAction(
                  key: Key(hash),
                  deleteConfirmation: () =>
                      CDissmissible.showDeleteConfirmationDialog(context),
                  confirmDeleteDismiss: () async {
                    if (currentData.currentGroup == null) {
                      SnackService().showError(
                        'Ein Fehler ist passiert, Bitte erst eine Gruppe auswählen!',
                      );
                      return false;
                    }
                    await dataProvider.removeSongFromGroup(
                        currentData.currentGroup!, hash);
                    (hash);
                    return true;
                  },
                  confirmActionDismiss: () {
                    exportSong(context, song);
                    return Future.value(false);
                  },
                  child: CListTile(
                    title: name,
                    subtitle: song.header.authors.isNotEmpty
                        ? song.header.authors[0]
                        : '',
                    context: context,
                    onTap: () {
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
                    onLongPress: () {
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
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
