import 'dart:convert';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/parseChords.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/lyricsChordsClass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/displayFunctions.dart';

//Future<Map<String, dynamic>?> loadSongData(
//  final globalSongData,
//  Function displaySnack,
//) async {
//  try {
//    //Map<String, dynamic>? loadedSongDatas =
//    //    await MultiJsonStorage.loadJsonsFromGroup(currentSongData.currentGroup);
//    final Map songData = globalSongData.groupSongMap['data'] ?? {};
//    final String key = globalSongData.currentKey;
//    final mappings = await loadMappings(
//      'assets/nashville_to_chord_by_key.json',
//      displaySnack,
//    );
//
//    // Debug Statements
//    if (songData.isEmpty) {
//      displaySnack('No data found for the provided group.');
//      return null;
//    } else if (mappings == null) {
//      displaySnack('No mappings found.');
//      return null;
//    }
//
//    // Add all SongStructureWidgets
//    Map<String, List<Widget>> songStructures = {};
//    songData.forEach((key, value) {
//      List<Widget> songStructure = buildSetionWidgets(
//        value['data'],
//        displaySnack,
//        (chordsData) => parseChords(
//          chordsData,
//          mappings,
//          key,
//          displaySnack,
//        ),
//      );
//      songStructures[key] = songStructure;
//    });
//    return songStructures;
//  } catch (e) {
//    print(e);
//    displaySnack('An error occurred while loading song data: $e');
//    return null;
//  }
//}

Widget buildSetionWidget(
  String sectionTitle,
  List sectionContent,
  Function parseChords,
  Function displaySnack,
) {
  Widget sectionWidget;
  List<Widget> sectionStruct = [];
  // Verse/chorus label
  sectionStruct.add(Text(
    sectionTitle.toUpperCase(),
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ));

  sectionStruct.add(const SizedBox(height: 10));

  for (var lineData in sectionContent) {
    if (lineData is Map<String, dynamic>) {
      sectionStruct.add(LyricsWithChords(
        lyrics: lineData['lyrics'] ?? '',
        chords: parseChords(lineData['chords']),
      ));
    } else {
      displaySnack('Unexpected line data format: $lineData');
    }
  }
  sectionStruct.add(const SizedBox(height: 20));

  sectionWidget = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: sectionStruct,
  );
  return sectionWidget;
}

//List<Widget> buildSetionWidgets(
//  Map<String, dynamic> data,
//  Function displaySnack,
//  Function parseChords,
//) {
//  List<Widget> sectionWidgets = [];
//
//  data.forEach((section, content) {
//    List<Widget> oneSection = [];
//    // Verse/chorus label
//    oneSection.add(Text(
//      section.toUpperCase(),
//      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//    ));
//
//    oneSection.add(const SizedBox(height: 10));
//
//    if (content is List<dynamic>) {
//      for (var lineData in content) {
//        if (lineData is Map<String, dynamic>) {
//          oneSection.add(LyricsWithChords(
//            lyrics: lineData['lyrics'] ?? '',
//            chords: parseChords(lineData['chords']),
//          ));
//        } else {
//          displaySnack('Unexpected line data format: $lineData');
//        }
//      }
//    } else {
//      displaySnack('Unexpected content format for section $section: $content');
//    }
//    oneSection.add(const SizedBox(height: 20));
//
//    // HERE
//    sectionWidgets.add(
//      Column(
//        crossAxisAlignment: CrossAxisAlignment.start,
//        children: oneSection,
//      ),
//    );
//  });
//  return sectionWidgets;
//}

Future<Map<String, Map<String, String>>?> loadMappings(
  String jsonFilePath,
  Function displaySnack,
) async {
  try {
    String jsonString = await rootBundle.loadString(jsonFilePath);
    final dynamic decodedJson = json.decode(jsonString);

    return (decodedJson as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        (value as Map<String, dynamic>).map(
          (subKey, subValue) => MapEntry(subKey, subValue as String),
        ),
      ),
    );
  } catch (e) {
    displaySnack(e.toString());
    return null;
  }
}
