import 'dart:convert';
import 'package:P2pChords/dataManagment/comparer/functions.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class MultiJsonStorage {
  static const String _keyPrefix = 'data';
  static bool _initialized = false;
  static bool _recoveryModeRequired = false;

  // Initialize SharedPreferences safely before app starts
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Try to access SharedPreferences at the most basic level
      final prefs = await SharedPreferences.getInstance();

      try {
        // Try to read the group map
        final groupMapString = prefs.getString('$_keyPrefix:group_map');

        // If we get here without error and groupMapString is valid JSON or null, we're ok
        if (groupMapString == null || isValidJson(groupMapString)) {
          // Initialize an empty map if needed
          if (groupMapString == null) {
            await prefs.setString('$_keyPrefix:group_map', '{}');
          }
        } else {
          // Invalid JSON, need to reset
          _recoveryModeRequired = true;
        }
      } catch (e) {
        // Any error means we need recovery
        SnackService().showError('Error checking group map: $e');
        _recoveryModeRequired = true;
      }

      // If recovery is needed, clear everything
      if (_recoveryModeRequired) {
        SnackService()
            .showError('Recovery mode activated - clearing all preferences');
        await _emergencyClearAllPreferences();
      }

      _initialized = true;
    } catch (e) {
      SnackService().showError('Critical error during initialization: $e');
      // Try one last emergency clear
      await _emergencyResetSharedPrefs();
      _initialized = true;
    }
  }

  // Special method to completely clear SharedPreferences using a separate instance
  static Future<void> _emergencyClearAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // Re-initialize with an empty JSON object for group map
      await prefs.setString('$_keyPrefix:group_map', '{}');
      SnackService().showError('Emergency clear completed');
    } catch (e) {
      SnackService().showError('Error during emergency clear: $e');
      // Last resort - try to use a brand new SharedPreferences instance
      await _emergencyResetSharedPrefs();
    }
  }

  // Most extreme method - tries to recreate SharedPreferences from scratch
  static Future<void> _emergencyResetSharedPrefs() async {
    try {
      // Force a new instance
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setString('$_keyPrefix:group_map', '{}');
      SnackService().showError('SharedPreferences recreated');
    } catch (e) {
      SnackService().showError('Failed to recreate SharedPreferences: $e');
    }
  }

  // Helper to check if a string is valid JSON
  static bool isValidJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return false;
    }

    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> compareSongData(prefs, string1, string2, songName) async {
    if (string2 != string1) {
      String confTxt =
          'Ein Song mit dem Namen $songName existiert bereits. Möchtest du ihn überschreiben?';
      return await openSongComparisonDialog(
        confTxt,
        string1,
        string2,
      );
    } else {
      return true;
    }
  }

  static Future<Map<String, List<String>>> getGroupMap(
      SharedPreferences prefs) async {
    try {
      // Always check if initialized
      if (!_initialized) await initialize();

      String? groupMapString;
      try {
        groupMapString = prefs.getString('$_keyPrefix:group_map');
      } catch (e) {
        debugPrint('Error reading group map: $e');
        // Reset group map
        await prefs.setString('$_keyPrefix:group_map', '{}');
        groupMapString = '{}';
      }

      if (groupMapString == null || groupMapString.isEmpty) {
        await prefs.setString('$_keyPrefix:group_map', '{}');
        return <String, List<String>>{};
      }

      try {
        Map<String, dynamic> decodedMap = jsonDecode(groupMapString);
        Map<String, List<String>> groupMap = {};

        decodedMap.forEach((key, value) {
          if (value is List) {
            groupMap[key] =
                List<String>.from(value.map((item) => item.toString()));
          }
        });
        return groupMap;
      } catch (e) {
        debugPrint('Invalid JSON in group map: $e');
        await prefs.setString('$_keyPrefix:group_map', '{}');
        return <String, List<String>>{};
      }
    } catch (e) {
      debugPrint('Error in getGroupMap: $e');
      return <String, List<String>>{};
    }
  }

  static Future<bool> saveJson(Song song, {String? group}) async {
    final prefs = await SharedPreferences.getInstance();

    if (song.hash == sha256.convert(utf8.encode('empty')).toString()) {
      return false;
    }

    // Convert the Song to JSON string
    String jsonString = jsonEncode(song.toMap());
    // Use the hash value from the song object
    final String savePath = '$_keyPrefix:songs:${song.hash}';

    // Check if the song already exists
    if (prefs.containsKey(savePath)) {
      bool doContinue = await compareSongData(
          jsonString, prefs.getString(savePath), jsonString, song.header.name);
      if (!doContinue) {
        return false;
      }
    }

    await prefs.setString(savePath, jsonString);
    if (group != null) {
      await addSongToGroup(group, song.hash);
    }
    return true;
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
    try {
      // Always check if initialized
      if (!_initialized) await initialize();

      final prefs = await SharedPreferences.getInstance();
      String? jsonString;

      try {
        jsonString = prefs.getString('$_keyPrefix:songs:$key');
      } catch (e) {
        debugPrint('Error reading song data: $e');
        return null;
      }

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      try {
        Map<String, dynamic> songData = jsonDecode(jsonString);
        return Song.fromMap(songData);
      } catch (e) {
        debugPrint('Error parsing song data for key $key: $e');
        try {
          await prefs.remove('$_keyPrefix:songs:$key');
        } catch (e2) {
          debugPrint('Error removing corrupted song: $e2');
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error loading song: $e');
      return null;
    }
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

  /// Update the order of songs in a group
  static Future<void> updateGroupOrder(String groupName, List<String> orderedHashes) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get the current group map
    Map<String, List<String>> groupMap = await getGroupMap(prefs);
    
    // Update the specific group with the new order
    if (groupMap.containsKey(groupName)) {
      groupMap[groupName] = orderedHashes;
      
      // Save back to SharedPreferences
      await prefs.setString('$_keyPrefix:group_map', jsonEncode(groupMap));
    }
  }

  static Future<void> saveGroupOrder(List<String> groupNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_keyPrefix:group_order', groupNames);
  }

  static Future<List<String>?> getGroupOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_keyPrefix:group_order');
  }

  static Future<List<String>> getAllSongHashs(SharedPreferences prefs) async {
    try {
      Set<String> allKeys;

      try {
        allKeys = prefs.getKeys();
      } catch (e) {
        debugPrint('Error getting keys: $e');
        return [];
      }

      final Iterable<String> songKeys =
          allKeys.where((String key) => key.startsWith('$_keyPrefix:songs:'));

      // Load each Hash and add to the list
      List<String> allHashes = [];
      for (String key in songKeys) {
        String hash = key.substring('$_keyPrefix:songs:'.length);
        allHashes.add(hash);
      }
      return allHashes;
    } catch (e) {
      debugPrint('Error getting all song hashes: $e');
      return [];
    }
  }

  static Future<SongData> getSavedSongsData() async {
    // Make sure we've initialized properly first
    try {
      await initialize();

      final prefs = await SharedPreferences.getInstance();

      Map<String, List<String>> groupMap = {};
      Map<String, Song> songMap = {};

      try {
        // Get group map
        groupMap = await getGroupMap(prefs);

        // Get all song hashes
        List<String> allHashes = await getAllSongHashs(prefs);

        // Load all songs
        for (String hash in allHashes) {
          Song? song = await loadJson(hash);
          if (song != null) {
            songMap[hash] = song;
          }
        }
      } catch (e) {
        debugPrint('Error building SongData: $e');
      }

      return SongData.fromDataProvider(groupMap, songMap);
    } catch (e) {
      debugPrint('Error in getSavedSongsData: $e');

      // Return empty data in case of any error
      return SongData.fromDataProvider({}, {});
    }
  }
}
