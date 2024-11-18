import 'dart:convert';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/parseChords.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/lyricsChordsClass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/displayFunctions.dart';

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
