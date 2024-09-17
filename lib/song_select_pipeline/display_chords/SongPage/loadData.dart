import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';

Future<Map<String, dynamic>?> loadSongData(
  final currentSongData,
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
    //print(currentSongData.currentGroup);
    Map<String, dynamic>? loadedSongDatas =
        await MultiJsonStorage.loadJsonsFromGroup(currentSongData.currentGroup);
    if (loadedSongDatas.isEmpty) {
      displaySnack('No data found for the provided group.');
      return null;
    }
    // Add all SongStructureWidgets
    Map<String, List<Widget>> songStructures = {};
    //print(loadedSongDatas);
    loadedSongDatas.forEach((key, value) {
      List<Widget> songStructure = buildSongContent(
        value['data'],
        displaySnack,
        (chordsData) => parseChords(
          chordsData,
          nashvilleToChordMapping,
          currentKey,
          displaySnack,
        ),
      );
      songStructures[key] = songStructure;
    });

    return {
      'songDatas': loadedSongDatas,
      'songStructures': songStructures,
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
