import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:P2pChords/data_management/save_json_in_storage.dart';

Future<Map<String, dynamic>?> loadSongData(
  String songHash,
  Function displaySnack,
  List<Widget> Function(Map<String, dynamic>, Function, Function)
      buildSongContent,
  Map<String, String> Function(
          dynamic, Map<String, Map<String, String>>, String, Function)
      parseChords,
  Map<String, Map<String, String>> nashvilleToChordMapping,
  String currentKey,
) async {
  try {
    Map<String, dynamic>? loadedSongData =
        await MultiJsonStorage.loadJson(songHash);

    if (loadedSongData == null) {
      displaySnack('No data found for the provided hash.');
      return null;
    }

    List<Widget> songStructure = buildSongContent(
      loadedSongData['data'],
      displaySnack,
      (chordsData) => parseChords(
        chordsData,
        nashvilleToChordMapping,
        currentKey,
        displaySnack,
      ),
    );

    return {
      'songData': loadedSongData,
      'songStructure': songStructure,
    };
  } catch (e) {
    print(e);
    displaySnack('An error occurred while loading song data: $e');
    return null;
  }
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
