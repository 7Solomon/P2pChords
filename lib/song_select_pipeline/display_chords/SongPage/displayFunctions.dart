import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/loadData.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/parseChords.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/lyricsChordsClass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

List<Widget> displaySectionContent({
  required globalData,
  required uiDisplaySectionData, // How many Sections should be displayed should be regulated in here you understand
  required String key,
  required Map<String, Map<String, String>> mappings, // For the Nahsville stuff
  required final void Function(String) displaySnack,
}) {
  List<Widget> displayData = [];

  //final currentSongHash = globalData.currentSongHash;
  //final currentSongData = globalData.songsDataMap[currentSongHash] ?? {};
  //final currentSongName = currentSongData['header']['name'] ?? 'noName';

  //List currentSongDataList = currentSongData.entries.toList();

  // Add all requested sections
  final songsData = globalData.songsDataMap ?? {};
  for (var toDisplaySong in uiDisplaySectionData.entries) {
    String toDisplaySongHash = toDisplaySong.key;
    List<int> toDisplaySections = toDisplaySong.value;

    final songData = songsData[toDisplaySongHash];
    final SongName = songData['header']['name'] ?? 'noName';
    final songDataList = songData['data'].entries.toList();
    // Hier die Logic mit uiDisplay Data adden denke ich

    for (int index in toDisplaySections) {
      final section = songDataList[index];
      if (section != null) {
        String sectionTitle = section.key;
        List sectionContent = section.value;

        displayData.add(buildSetionWidget(
            sectionTitle,
            sectionContent,
            (chordsData) => parseChords(
                  chordsData,
                  mappings,
                  key,
                  displaySnack,
                ),
            displaySnack));
      } else
        print('Section not found');
      //displaySnack('Section not found');      Eigeintlich besser aber fürht zu Noch bug wegen not build und so
    }
  }

  if (displayData.isEmpty) {
    return [const Text('Keine Songdaten verfügbar')];
  }
  return displayData;
}
