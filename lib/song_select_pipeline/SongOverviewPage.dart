import 'dart:convert';
import 'dart:math';

import 'package:P2pChords/dataManagment/Pages/editJsonPage.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/uiSettings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/SongPage.dart';

import 'package:P2pChords/customeWidgets/TileWidget.dart';

class Songoverviewpage extends StatelessWidget {
  //final VoidCallback onGroupDeleted;
  //final Map<String, dynamic> songsData;

  const Songoverviewpage({super.key});

  @override
  Widget build(BuildContext context) {
    //final songSyncProvider =
    //    Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    final globalSongData = context.watch<UiSettings>();
    final musicSyncProvider = context.watch<NearbyMusicSyncProvider>();

    //print(songSyncProvider.currentGroup);
    return Scaffold(
      appBar: AppBar(
        title: Text('Songs in ${globalSongData.currentGroup}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: globalSongData.songsDataMap.length,
              itemBuilder: (context, index) {
                final hash = globalSongData.songsDataMap.keys.elementAt(index);
                final song = globalSongData.songsDataMap[hash]!;
                final name = song['header']['name'] ?? 'noName';

                return CustomListTile(
                  title: name,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16.0),
                  iconBool: false,
                  onTap: () {
                    // FOR DEBUGGING
                    globalSongData.setCurrentSong(hash);
                    globalSongData.getListOfDisplaySections(0);
                    //globalSongData.getListOfDisplaySectionsExperimental(0);
                    musicSyncProvider.sendUpdateToClients(
                        globalSongData.currentSongHash,
                        globalSongData.startIndexofSection,
                        globalSongData.currentGroup);
                    //musicSyncProvider.sendUpdateToClients(hash, 0);

                    ///
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChordSheetPage(),
                      ),
                    );
                  },
                  onLongPress: () {
                    // Edit Json Data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JsonEditPage(
                          jsonData: song,
                          saveJson: (String json) {
                            MultiJsonStorage.saveJson(hash, jsonDecode(json),
                                group: globalSongData.currentGroup);
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
