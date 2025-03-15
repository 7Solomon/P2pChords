import 'dart:convert';
import 'dart:math';

import 'package:P2pChords/dataManagment/Pages/editJsonPage.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/ChordSheetPage.dart';

import 'package:P2pChords/customeWidgets/TileWidget.dart';

class Songoverviewpage extends StatelessWidget {
  const Songoverviewpage({super.key});

  @override
  Widget build(BuildContext context) {
    //final songSyncProvider =
    //    Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    final currentData = context.watch<CurrentSelectionProvider>();
    final dataProvider = context.watch<DataLoadeProvider>();
    final musicSyncProvider = context.watch<NearbyMusicSyncProvider>();

    //print(songSyncProvider.currentGroup);
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
                return CustomListTile(
                  title: name,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16.0),
                  iconBool: false,
                  onTap: () {
                    currentData.setCurrentSong(hash);
                    currentData.setCurrentSongIndex(0);

                    musicSyncProvider.sendUpdateToClients(currentData.toJson());

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
