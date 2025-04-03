import 'dart:convert';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/songComparer.dart';
import 'package:P2pChords/navigator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crypto/crypto.dart'; // Add this package to generate the hash

class MultiJsonStorage {
  static const String _keyPrefix = 'data';

  // For debug
  static Future<void> printAllWithPrefix() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys(); // Retrieve all keys stored in SharedPreferences

    // Iterate through all keys and check if they start with the given prefix
    for (String key in keys) {
      String? value = prefs.getString(key);
      print('Key: $key, Value: $value');
    }
  }

  //static resetGroupMap() async {
  //  final prefs = await SharedPreferences.getInstance();
  //  await prefs.remove('$_keyPrefix:group_map');
  //}

  static Future<bool> compareSongData(prefs, string1, string2, songName) async {
    if (string2 != string1) {
      Map<String, dynamic> differences = compareJson(string2, string1);
      String confTxt =
          'Ein Song mit dem Namen $songName existiert bereits. Möchtest du ihn überschreiben?';
      return await openDiffrenceWindow(confTxt, differences: differences);
    } else {
      return true;
    }
  }

  static Future<Map<String, List<String>>> getGroupMap(
      SharedPreferences prefs) async {
    final groupMapString = prefs.getString('$_keyPrefix:group_map');

    if (groupMapString == null) {
      return <String, List<String>>{};
    }
    Map<String, dynamic> decodedMap = jsonDecode(groupMapString);
    Map<String, List<String>> groupMap = {};

    decodedMap.forEach((key, value) {
      if (value is List) {
        groupMap[key] = List<String>.from(value.map((item) => item.toString()));
      }
    });
    return groupMap;
  }

  static saveJson(Song song, {String group = 'default'}) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert the Song to JSON string
    String jsonString = jsonEncode(song.toMap());
    // Use the hash value from the song object
    final String savePath = '$_keyPrefix:songs:${song.hash}';

    // Check if the song already exists
    if (prefs.containsKey(savePath)) {
      bool doContinue = await compareSongData(
          jsonString, prefs.getString(savePath), jsonString, song.header.name);
      if (!doContinue) {
        return;
      }
    }

    await prefs.setString(savePath, jsonString);
    await addSongToGroup(group, song.hash);
  }

  static addSongToGroup(String group, String hash) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, List<String>> groupMap = await getGroupMap(prefs);

    if (!groupMap.containsKey(group)) {
      groupMap[group] = [];
    }

    if (!groupMap[group]!.contains(hash)) {
      groupMap[group]!.add(hash);
    }

    await prefs.setString('$_keyPrefix:group_map', jsonEncode(groupMap));
  }

  static Future<void> saveNewGroup(String name) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, List<String>> groupMap = await getGroupMap(prefs);

    if (!groupMap.containsKey(name)) {
      groupMap[name] = [];
      await prefs.setString('$_keyPrefix:group_map', jsonEncode(groupMap));
    } else {
      groupMap[name] = [];
      await prefs.setString('$_keyPrefix:group_map', jsonEncode(groupMap));
    }
  }

  static Future<void> saveSongsData(SongData songData) async {
    for (var group in songData.groups.entries) {
      await saveNewGroup(group.key);
      for (String hash in group.value) {
        Song? song = songData.songs[hash];
        if (song != null) {
          await saveJson(song, group: group.key);
        }
      }
    }
  }

  static Future<Song?> loadJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('$_keyPrefix:songs:$key');

    if (jsonString != null) {
      Map<String, dynamic> songData = jsonDecode(jsonString);
      return Song.fromMap(songData);
    }
    return null;
  }

  static Future<void> removeJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix:songs:$key');
  }

  static Future<void> removeJsonFromGroup(String group, String jsonHash) async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve the current group map
    Map<String, List<String>> groupMap = await getGroupMap(prefs);

    // Get the list of songs in the group
    List<String> songList = groupMap[group] ?? [];

    // Remove the song from the group based on the hash
    songList.removeWhere((hash) => hash == jsonHash);

    // Update the group map
    if (songList.isEmpty) {
      groupMap.remove(group); // If no songs left, remove the group entry
    } else {
      groupMap[group] = songList;
    }

    // Save the updated group map back to SharedPreferences
    await prefs.setString('$_keyPrefix:group_map', jsonEncode(groupMap));
  }

  static Future<void> removeGroup(String groupName) async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve the current group map
    Map<String, List<String>> groupMap = await getGroupMap(prefs);

    // Return if not exists
    if (!groupMap.containsKey(groupName)) {
      return;
    }

    // Get the list of songs in the group
    List<String> songList = groupMap[groupName] ?? [];

    // Remove all songs from the group
    for (String hash in songList) {
      await removeJson(hash);
    }

    // Remove the group from the group map
    groupMap.remove(groupName);

    prefs.setString('$_keyPrefix:group_map', jsonEncode(groupMap));
  }

  static Future<List<String>> getAllSongHashs() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final songKeys =
        allKeys.where((key) => key.startsWith('$_keyPrefix:songs:'));

    // Load each Hash and add to the list
    List<String> allHashes = [];
    for (String key in songKeys) {
      String hash = key.substring('$_keyPrefix:songs:'.length);
      allHashes.add(hash);
    }
    return allHashes;
  }

  static Future<SongData> getSavedSongsData() async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve the data
    Map<String, List<String>> groupMap = await getGroupMap(prefs);
    List<String> allHashes = await getAllSongHashs();

    Map<String, Song> songMap = {};
    for (String hash in allHashes) {
      Song? song = await loadJson(hash);
      if (song != null) {
        songMap[hash] = song;
      }
    }
    return SongData.fromDataProvider(groupMap, songMap);
  }
}
