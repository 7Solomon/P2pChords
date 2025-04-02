import 'dart:convert';
import 'dart:math';

import 'package:P2pChords/dataManagment/Pages/editJsonPage.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawer.dart';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Songs in ${currentData.currentGroup}'),
      ),
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
                return CListTile(
                  title: name,
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
                        builder: (context) => JsonEditPage(
                          song: song,
                          saveJson: (String json) {
                            print('Not implemented');
                            //MultiJsonStorage.saveJson(hash, jsonDecode(json),
                            //    group: globalSongData.currentGroup);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ) //;
          //})
        ],
      ),
    );
  }
}
