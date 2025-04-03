import 'dart:convert';

import 'package:P2pChords/dataManagment/comparer/Dialog.dart';
import 'package:P2pChords/dataManagment/comparer/components.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/navigator.dart';
import 'package:flutter/material.dart';

/// Compares two songs and presents a visual comparison dialog.
/// If existingJson is null or empty, shows a simple confirmation dialog.
/// Returns true if the user accepts the changes, false otherwise.
Future<bool> openSongComparisonDialog(
    String message, String? existingJson, String newJson) async {
  // Handle case for new songs (no existing song to compare)
  if (existingJson == null || existingJson.isEmpty) {
    return await showDialog<bool>(
          context: NavigationService.navigatorKey.currentState!.context,
          builder: (context) => AlertDialog(
            title: const Text('Neuer Song'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('Abbrechen'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Speichern'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Parse both songs and show the comparison dialog
  try {
    final existingSong = Song.fromMap(jsonDecode(existingJson));
    final newSong = Song.fromMap(jsonDecode(newJson));

    return await showDialog<bool>(
          context: NavigationService.navigatorKey.currentState!.context,
          builder: (context) => SongComparisonDialog(
            message: message,
            existingSong: existingSong,
            newSong: newSong,
          ),
        ) ??
        false;
  } catch (e) {
    // Fallback to text-based comparison in case of parsing errors
    final differences = compareJson(existingJson, newJson);
    return await openDifferenceWindow(message, differences: differences);
  }
}

/// Entry point for comparing songs, supports both visual and text-based comparison
Future<bool> openDifferenceWindow(
  String message, {
  Map<String, dynamic>? differences,
  String? existingJson,
  String? newJson,
}) async {
  // If we have raw JSON, use the visual comparison
  if (existingJson != null && newJson != null) {
    return await openSongComparisonDialog(message, existingJson, newJson);
  }

  // Otherwise fall back to the text-based comparison
  return await showDialog(
        context: NavigationService.navigatorKey.currentState!.context,
        builder: (context) => AlertDialog(
          title: const Text('Bestätige bitte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (differences != null && differences.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  buildDifferencesHeader(context),
                  const SizedBox(height: 8),
                  ...differences.entries.map((entry) =>
                      buildDifferenceItem(context, entry.key, entry.value)),
                ]
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Nein'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Ja'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ) ??
      false;
}

/// Compare two JSON strings and return a map of differences
Map<String, dynamic> compareJson(String? existingJson, String newJson) {
  // Handle null or empty existing string (indicates a completely new song)
  if (existingJson == null || existingJson.isEmpty) {
    return {'Gesamter Inhalt': 'Neuer Song'};
  }

  var existingData = jsonDecode(existingJson);
  var newData = jsonDecode(newJson);

  Map<String, dynamic> differences = {};
  findDifferences(existingData, newData, path: [], differenceMap: differences);

  return differences;
}

/// Recursively finds differences between two objects
void findDifferences(dynamic existingObj, dynamic newObj,
    {required List<String> path, required Map<String, dynamic> differenceMap}) {
  // Check for added values
  if (existingObj == null && newObj != null) {
    addDifference(
        differenceMap, path, 'Neuer Wert', 'Wert wurde hinzugefügt: $newObj');
    return;
  }

  // Check for type differences
  if (existingObj.runtimeType != newObj.runtimeType) {
    addDifference(differenceMap, path, 'Typunterschied',
        '${existingObj.runtimeType} vs ${newObj.runtimeType}');
    return;
  }

  // Handle map comparison
  if (existingObj is Map) {
    _compareMapObjects(existingObj, newObj, path, differenceMap);
  }
  // Handle list comparison
  else if (existingObj is List) {
    _compareListObjects(existingObj, newObj, path, differenceMap);
  }
  // Compare primitive values
  else if (existingObj != newObj) {
    addDifference(differenceMap, path, 'Wertunterschied', 'Geänderte Werte:',
        existingValue: existingObj.toString(), newValue: newObj.toString());
  }
}

/// Compare two Map objects and find differences
void _compareMapObjects(Map existingObj, Map newObj, List<String> path,
    Map<String, dynamic> differenceMap) {
  // Check for keys in existingObj not in newObj
  for (var key in existingObj.keys) {
    if (!newObj.containsKey(key)) {
      addDifference(differenceMap, path, 'Fehlender Schlüssel',
          "Schlüssel '$key' fehlt in neuem JSON");
      continue;
    }
    findDifferences(existingObj[key], newObj[key],
        path: [...path, key], differenceMap: differenceMap);
  }

  // Check for keys in newObj not in existingObj
  for (var key in newObj.keys) {
    if (!existingObj.containsKey(key)) {
      addDifference(differenceMap, path, 'Zusätzlicher Schlüssel',
          "Schlüssel '$key' fehlt in bestehendem JSON");
    }
  }
}

/// Compare two List objects and find differences
void _compareListObjects(List existingObj, List newObj, List<String> path,
    Map<String, dynamic> differenceMap) {
  int minLength =
      existingObj.length < newObj.length ? existingObj.length : newObj.length;

  // Compare items up to the minimum length of both lists
  for (int i = 0; i < minLength; i++) {
    findDifferences(existingObj[i], newObj[i],
        path: [...path, '[$i]'], // Fixed: properly formatted index
        differenceMap: differenceMap);
  }

  // Handle different list lengths
  if (existingObj.length > newObj.length) {
    addDifference(differenceMap, path, 'Fehlende Elemente',
        "Elemente im neuen JSON fehlen: ${existingObj.sublist(newObj.length)}");
  } else if (newObj.length > existingObj.length) {
    addDifference(differenceMap, path, 'Neue Elemente',
        "Neue Elemente hinzugefügt: ${newObj.sublist(existingObj.length)}");
  }
}

/// Add a difference to the difference map
void addDifference(Map<String, dynamic> differenceMap, List<String> path,
    String type, String description,
    {String existingValue = 'null', String newValue = 'null'}) {
  String pathKey = path.isEmpty ? 'Wurzel' : path.join(' > ');

  if (existingValue != 'null' && newValue != 'null') {
    differenceMap[pathKey] = {
      'typ': type,
      'beschreibung': description,
      'obj1':
          existingValue, // Using obj1/obj2 for compatibility with existing code
      'obj2': newValue,
    };
  } else {
    differenceMap[pathKey] = {'typ': type, 'beschreibung': description};
  }
}
